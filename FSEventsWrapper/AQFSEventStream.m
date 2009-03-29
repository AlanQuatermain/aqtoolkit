/*
 *  AQFSEventStream.m
 *  AQToolkit
 *
 *  Created by Jim Dovey on 17/2/2009.
 *
 *  Copyright (c) 2009, Jim Dovey
 *  All rights reserved.
 *  
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *
 *  Redistributions of source code must retain the above copyright notice,
 *  this list of conditions and the following disclaimer.
 *  
 *  Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *  
 *  Neither the name of this project's author nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
 *  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 *  HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 *  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 *  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
