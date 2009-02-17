/*
 *  AQFSEventStream.m
 *  AQToolkit
 *
 *  Created by Jim Dovey on 17/2/2009.
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

#import "AQFSEventStream.h"

// the framework's default latency. Use +setDefaultLatency: to modify this value
static CFAbsoluteTime __latency = 5.0;

static void _AQFSEventStreamCallback( ConstFSEventStreamRef stream, void * info, size_t numEvents,
									  void * eventPaths, const FSEventStreamEventFlags eventFlags[],
									  const FSEventStreamEventId eventIds[] )
{
	NSArray * paths = (NSArray *) eventPaths;
	AQFSEventStream * obj = (AQFSEventStream *) info;
	
	// filter the array list-- get indices for items with no flags and for those with
	//  special flags
	NSMutableIndexSet * basicIndices = [NSMutableIndexSet indexSet];
	NSMutableIndexSet * specialIndices = [NSMutableIndexSet indexSet];
	
	NSUInteger i;
	for ( i = 0; i < numEvents; i++ )
	{
		if ( eventFlags[i] == kFSEventStreamEventFlagNone )
			[basicIndices addIndex: i];
		else
			[specialIndices addIndex: i];
	}
	
	// grab all the paths which have simply been updated
	NSArray * updatedPaths = [paths objectsAtIndexes: basicIndices];
	
	// push out this notification
	if ( updatedPaths.count != 0 )
		[obj.delegate foldersUpdated: updatedPaths];
	
	// step through the special ones, looking at the specific event flags
	i = [specialIndices firstIndex];
	
	while ( i != NSNotFound )
	{
		NSString * path = [paths objectAtIndex: i];
		FSEventStreamEventFlags flags = eventFlags[i];
		
		if ( flags & kFSEventStreamEventFlagHistoryDone )
		{
			if ( [obj.delegate respondsToSelector: @selector(eventHistoryDone)] )
				[obj.delegate eventHistoryDone];
		}
		
		if ( flags & kFSEventStreamEventFlagRootChanged )
		{
			if ( [obj.delegate respondsToSelector: @selector(rootPathChanged:)] )
				[obj.delegate rootPathChanged: path];
		}
		
		if ( flags & kFSEventStreamEventFlagMount )
		{
			if ( [obj.delegate respondsToSelector: @selector(volumeMounted:)] )
				[obj.delegate volumeMounted: path];
		}
		
		if ( flags & kFSEventStreamEventFlagUnmount )
		{
			if ( [obj.delegate respondsToSelector: @selector(volumeUnmounted:)] )
				[obj.delegate volumeUnmounted: path];
		}
		
		if ( flags & kFSEventStreamEventFlagMustScanSubDirs )
		{
			if ( [obj.delegate respondsToSelector: @selector(scanSubDirs:)] )
				[obj.delegate scanSubDirs: path];
		}
		
		i = [specialIndices indexGreaterThanIndex: i];
	}
}

#pragma mark -

@implementation AQFSEventStream

@dynamic lastEventId;
@synthesize delegate=_delegate;

+ (AQFSEventStream *) startedEventStreamForPaths: (NSSet *) paths
{
	AQFSEventStream * stream = [[self alloc] initWithPaths: paths];
	if ( stream == nil )
		return ( nil );
	
	[stream scheduleWithRunLoop: [NSRunLoop currentRunLoop] forMode: NSRunLoopCommonModes];
	[stream start];
	
	return ( [stream autorelease] );
}

+ (NSTimeInterval) defaultLatency
{
	return ( (NSTimeInterval) __latency );
}

+ (void) setDefaultLatency: (NSTimeInterval) latency
{
	__latency = (CFAbsoluteTime) latency;
}

+ (FSEventStreamEventId) currentEventId
{
	return ( FSEventsGetCurrentEventId() );
}

#pragma mark -

- (id) initWithPaths: (NSSet *) paths
{
	return ( [self initWithPaths: paths since: kFSEventStreamEventIdSinceNow] );
}

- (id) initWithPaths: (NSSet *) paths since: (FSEventStreamEventId) sinceWhen
{
	if ( [super init] == nil )
		return ( nil );
	
	FSEventStreamContext ctx = { 0, self, NULL, NULL, CFCopyDescription };
	_ref = FSEventStreamCreate( kCFAllocatorDefault, _AQFSEventStreamCallback, &ctx,
							    (CFArrayRef)[paths allObjects],  sinceWhen, __latency,
							    kFSEventStreamCreateFlagUseCFTypes |	// use CFArrayRef etc in callback
							    kFSEventStreamCreateFlagNoDefer |		// changes meaning of 'latency'
							    kFSEventStreamCreateFlagWatchRoot );	// also watch for root moving
	
	if ( _ref == NULL )
	{
		[self release];
		return ( nil );
	}
	
	return ( self );
}

- (void) dealloc
{
	FSEventStreamRelease( _ref );
	[super dealloc];
}

- (void) finalize
{
	FSEventStreamRelease( _ref );
	[super finalize];
}

- (void) scheduleWithRunLoop: (NSRunLoop *) runloop forMode: (NSString *) mode
{
	FSEventStreamScheduleWithRunLoop( _ref, [runloop getCFRunLoop], (CFStringRef)mode );
}

- (void) unscheduleFromRunLoop: (NSRunLoop *) runloop mode: (NSString *) mode
{
	FSEventStreamUnscheduleFromRunLoop( _ref, [runloop getCFRunLoop], (CFStringRef) mode );
}

- (void) start
{
	FSEventStreamStart( _ref );
}

- (void) stop
{
	FSEventStreamStop( _ref );
}

- (void) invalidate
{
	FSEventStreamInvalidate( _ref );
}

- (FSEventStreamEventId) lastEventId
{
	return ( FSEventStreamGetLatestEventId(_ref) );
}

- (void) flushEvents: (BOOL) sync
{
	if ( sync )
		FSEventStreamFlushSync( _ref );
	else
		FSEventStreamFlushAsync( _ref );
}

@end
