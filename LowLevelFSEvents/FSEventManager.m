/*
 *  FSEventManager.m
 *  AQToolkit
 *
 *  Created by Jim Dovey on 19/02/2009.
 *  Copyright (c) 2009 Jim Dovey. Some Rights Reserved.
 *
 *  This work is licensed under a Creative Commons
 *  Attribution License. You are free to use, modify,
 *  and redistribute this work, but may only distribute
 *  the resulting work under the same, similar or a
 *  compatible license. In addition, you must include
 *  the following disclaimer:
 *
 *    Portions Copyright (c) 2009 Jim Dovey
 *
 *  For license details, see:
 *    http://creativecommons.org/licenses/by-sa/3.0/
 *
 */

#import "FSEventManager.h"
#import "FSEvent.h"
#import "ASLogger.h"

#import <unistd.h>
#import <sys/ioctl.h>
#import <sys/types.h>
#import <sys/sysctl.h>
#import <sys/select.h>

static FSEventManager * __singleton = nil;
const int kFSEventBufferSize = 128 * 1024;

// ensure that 32-bit compilers treat this as 32-bit aligned
#pragma pack(4)
struct kfs_event_arg
{
	u_int16_t	type;
	u_int16_t	len;
	
	union
	{
		struct vnode *	vp;
		char			str[1];
		void *			ptr;
		int32_t			int32;
		dev_t			dev;
		ino_t			ino;
		int32_t			mode;
		uid_t			uid;
		gid_t			gid;
		uint64_t		timestamp;
		
	} data;	
};
typedef struct kfs_event_arg kfs_event_arg_t;

struct kfs_event
{
	int32_t			type;
	pid_t			pid;
	kfs_event_arg_t	args[FSE_MAX_ARGS];
};
typedef struct kfs_event kfs_event_t;
#pragma options align=reset

enum
{
	kFSEventThreadConditionRun,
	kFSEventThreadConditionStop,
	kFSEventThreadConditionStopped
};

#pragma mark -

@interface FSEvent (ArgumentBuilder)
- (void) addPathArgument: (NSString *) string;
- (void) addInodeArgument: (NSNumber *) inode;
@end

@implementation FSEvent (ArgumentBuilder)

- (void) addPathArgument: (NSString *) string
{
	@synchronized(_arguments)
	{
		// find a suitable key
		NSString * base = @"PATH";
		NSString * key = nil;
		
		int i = 1;
		do
		{
			key = [base stringByAppendingFormat: @"%d", i++];
		
		} while ( [_arguments objectForKey: key] != nil );
		
		// got our key, store the value
		[_arguments setObject: string forKey: key];
	}
}

- (void) addInodeArgument: (NSNumber *) inode
{
	@synchronized(_arguments)
	{
		// find a suitable key
		NSString * base = @"INO";
		NSString * key = nil;
		
		int i = 1;
		do
		{
			key = [base stringByAppendingFormat: @"%d", i++];
		
		} while ( [_arguments objectForKey: key] != nil );
		
		// got our key, store the value
		[_arguments setObject: inode forKey: key];
	}
}

@end

#pragma mark -

@interface FSEventManager (Internal)
- (BOOL) setupFSEventListener;
- (void) stop;
- (void) waitForEvents;
- (void) postEvent: (FSEvent *) event;
@end

@implementation FSEventManager

@synthesize handler=_handler;

+ (FSEventManager *) sharedManager
{
	@synchronized(self)
	{
		if ( __singleton == nil )
			__singleton = [[self alloc] init];
	}
	
	return ( __singleton );
}

+ (void) shutdown
{
	if ( __singleton == nil )
		return;
	
	@synchronized(self)
	{
		[__singleton stop];
		[__singleton release];
		__singleton = nil;
	}
}

- (id) init
{
	if ( [super init] == nil )
		return ( nil );
	
	_descriptor = -1;
	
	if ( [self setupFSEventListener] == NO )
	{
		[self release];
		return ( nil );
	}
	
	_threadStateLock = [[NSConditionLock alloc] initWithCondition: kFSEventThreadConditionRun];
	
	// run the event processing thread
	[NSThread detachNewThreadSelector: @selector(waitForEvents) toTarget: self withObject: nil];
	
	return ( self );
}

- (void) dealloc
{
	[self stop];
	[_threadStateLock release];
	[super dealloc];
}

- (void) finalize
{
	[self stop];
	[super finalize];
}

@end

@implementation FSEventManager (Internal)

- (BOOL) setupFSEventListener
{
	int clonefd;
	struct fsevent_clone_args clone_args;
	int8_t event_list[] = {
		FSE_REPORT,		// create file
		FSE_REPORT,		// delete
		FSE_REPORT,		// stat change
		FSE_REPORT,		// rename
		FSE_REPORT,		// content modification
		FSE_REPORT,		// exchange files
		FSE_REPORT,		// finder info change
		FSE_REPORT,		// create folder
		FSE_REPORT,		// chown
		FSE_REPORT,		// xattr modification
		FSE_REPORT		// xattr removal
	};
	
	ASLogNotice( @"Initializing FSEvent listener" );
	
	int fd = open( "/dev/fsevents", O_RDONLY );
	if ( fd < 0 )
	{
		ASLogError( @"Failed to open /dev/fsevents: %d (%s)", errno, strerror(errno) );
		return ( NO );
	}
	
	ASLogInfo( @"Opened /dev/fsevents" );
	
	clone_args.event_list = (int8_t *)event_list;
	clone_args.num_events = sizeof(event_list) / sizeof(int8_t);
	clone_args.event_queue_depth = 4096;
	clone_args.fd = &clonefd;
	
	if ( ioctl(fd, FSEVENTS_CLONE, (char *) &clone_args) < 0 )
	{
		ASLogError( @"Failed to clone fsevents fd: %d (%s)", errno, strerror(errno) );
		close( fd );
		return ( NO );
	}
	
	// close the original descriptor, we'll now be using the clone
	close( fd );
	
	ASLogInfo( @"Cloned fsevents device: %d", clonefd );
	
	// NB: Not asking for extended info right now
	
	_descriptor = clonefd;
	return ( YES );
}

- (void) stop
{
	if ( [_threadStateLock tryLockWhenCondition: kFSEventThreadConditionRun] == NO )
		return;		// already stopped
	
	// tell the thread to stop
	[_threadStateLock unlockWithCondition: kFSEventThreadConditionStop];
	
	// wait for it to actually do so
	[_threadStateLock lockWhenCondition: kFSEventThreadConditionStopped];
	
	if ( _descriptor != -1 )
	{
		close( _descriptor );
		_descriptor = -1;
	}
}

- (BOOL) threadShouldStop
{
	if ( [_threadStateLock tryLockWhenCondition: kFSEventThreadConditionStop] )
	{
		[_threadStateLock unlockWithCondition: kFSEventThreadConditionStopped];
		return ( YES );
	}
	
	return ( NO );
}

- (void) waitForEvents
{
	NSAutoreleasePool * rootPool = [[NSAutoreleasePool alloc] init];
	
	ASLogNotice( @"Starting fsevents reader thread" );
	
	// read from the device (we MUST pull data from the device in a timely manner)
	char buffer[kFSEventBufferSize];
	fd_set fds;
	FD_ZERO( &fds );
	
	while ( 1 )
	{
		// check for termination
		if ( [self threadShouldStop] )
			break;
		
		// wait for data to arrive
		FD_SET( _descriptor, &fds );
		struct timespec timeout = { 0, 200000000000 };		// 0.2 seconds
		int ret = pselect( _descriptor + 1, &fds, NULL, NULL, &timeout, NULL );
		if ( ret == -1 )
			continue;
		
		// must read any data or the kernel will be unhappy
		int numRead = read( _descriptor, buffer, kFSEventBufferSize );
		
		// if we've been terminated, stop now
		if ( [self threadShouldStop] )
			break;
		
		NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
		int offset = 0;
		while ( offset < numRead )
		{
			// get ptr to event structure
			kfs_event_t *pEvt = (kfs_event_t *)((char *)buffer + offset);
			
			// move offset up to the arguments
			offset += sizeof(int32_t) + sizeof(pid_t);
			
			ASLogDebug( @"Received event %#08x from proc %d", pEvt->type, pEvt->pid );
			
			FSEvent * event = [[FSEvent alloc] init];
			event.eventCode = pEvt->type & FSE_TYPE_MASK;
			event.processID = pEvt->pid;
			
			// read arguments
			kfs_event_arg_t *pArg = pEvt->args;
			while ( offset < numRead )
			{
				if ( pArg->type == FSE_ARG_DONE )
				{
					// no more arguments
					offset += sizeof(u_int16_t);
					break;
				}
				
				int argOffset = sizeof(pArg->type) + sizeof(pArg->len) + pArg->len;
				offset += argOffset;
				BOOL isVnode = NO;
				
				int argType = (pArg->type > FSE_MAX_ARGS) ? 0 : pArg->type;
				switch ( argType )
				{
					default:
						ASLogInfo( @"Unknown argument of type %hd, length %hd", pArg->type, pArg->len );
						break;
						
					case FSE_ARG_VNODE:
						// a path
						ASLogDebug( @"Vnode (path) - %s", (char *)&(pArg->data.vp) );
						isVnode = YES;
						break;
						
					case FSE_ARG_STRING:
						// a string (also a path...?)
						ASLogDebug( @"String - %s", pArg->data.str );
						[event addPathArgument: [NSString stringWithUTF8String: pArg->data.str]];
						break;
						
					case FSE_ARG_INT32:
						ASLogDebug( @"Int32 - %d", pArg->data.int32 );
						break;
						
					case FSE_ARG_RAW:
						ASLogDebug( @"Raw data, %d bytes", pArg->len );
						break;
						
					case FSE_ARG_INO:
						ASLogDebug( @"Inode number - %d", pArg->data.ino );
						[event addInodeArgument: [NSNumber numberWithInt: pArg->data.ino]];
						break;
						
					case FSE_ARG_UID:
						ASLogDebug( @"User ID - %d", pArg->data.uid );
						break;
						
					case FSE_ARG_GID:
						ASLogDebug( @"Group ID - %d", pArg->data.gid );
						break;
						
					case FSE_ARG_DEV:
						if ( isVnode )
						{
							ASLogDebug( @"File system ID - %#08x", pArg->data.dev );
							isVnode = NO;
						}
						else
						{
							ASLogDebug( @"Device - %#08x (major %u, minor %u)", pArg->data.dev,
									    major(pArg->data.dev), minor(pArg->data.dev) );
						}
						break;
						
					case FSE_ARG_MODE:
					{
						mode_t mode = (pArg->data.mode & 0x0000ffff);
						u_int32_t type = (pArg->data.mode & 0xfffff000);
						char str[12];
						strmode( mode, str );
						ASLogDebug( @"Mode - %s, type - %#08x", str, type );
						break;
					}
						
					case FSE_ARG_INT64:
						ASLogDebug( @"Timestamp - %llu", pArg->data.timestamp );
						event.timestamp = pArg->data.timestamp;
						break;
				}
				
				pArg = (kfs_event_arg_t *)((char *)pArg + argOffset);
			
			} // for each argument
			
			// done processing - post the event on the main thread
			[self performSelectorOnMainThread: @selector(postEvent:)
								   withObject: event
								waitUntilDone: NO];
			[event release];
			
			[pool drain];
			
			if ( [self threadShouldStop] )
				break;
		
		} // for each event
	} // event processing loop
	
	[rootPool drain];
}

- (void) postEvent: (FSEvent *) event
{
	[_handler handleEvent: event];
}

@end
