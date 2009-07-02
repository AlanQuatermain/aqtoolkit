/*
 *  AQConnectionMultiplexer.m
 *  AQToolkit
 *
 *  Created by Jim Dovey on 29/01/09.
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

#import "AQConnectionMultiplexer.h"
#import "AQLowMemoryDownloadHelper.h"

static AQConnectionMultiplexer * __connectionMultiplexer = nil;

@interface AQConnectionMultiplexer ()
- (void) _addHelper: (AQLowMemoryDownloadHelper *) helper;
@end

@implementation AQConnectionMultiplexer

+ (void) attachDownloadHelper: (AQLowMemoryDownloadHelper *) helper
{
	@synchronized(self)
	{
		if ( __connectionMultiplexer == nil )
		{
			__connectionMultiplexer = [[AQConnectionMultiplexer alloc] init];
			[__connectionMultiplexer start];
		}
	}
	
	[__connectionMultiplexer performSelector: @selector(_addHelper:)
									onThread: __connectionMultiplexer
								  withObject: helper
							   waitUntilDone: YES];
}

+ (void) removeDownloadHelper: (AQLowMemoryDownloadHelper *) helper
{
	if ( __connectionMultiplexer == nil )
		return;
	
	[__connectionMultiplexer performSelector: @selector(_removeHelper:)
									onThread: __connectionMultiplexer
								  withObject: helper
							   waitUntilDone: YES];
}

+ (void) cancelPendingTransfers
{
	NSThread * thread = nil;
	@synchronized(self)
	{
		thread = [__connectionMultiplexer retain];
	}
	
	if ( thread == nil )
		return;
	
	[__connectionMultiplexer performSelector: @selector(_cancelTransfers)
									onThread: thread
								  withObject: nil
							   waitUntilDone: YES];
	
	[thread release];
}

- (id) init
{
	if ( [super init] == nil )
		return ( nil );
	
	_downloadHelpers = [[NSMutableSet alloc] init];
	_runThread = YES;
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(terminate)
#ifdef IPHONEOS_DEPLOYMENT_TARGET
												 name: UIApplicationWillTerminateNotification
#else
												 name: NSApplicationWillTerminateNotification
#endif
											   object: nil];
	
	return ( self );
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[_downloadHelpers release];
	[super dealloc];
}

- (void) terminate
{
	__connectionMultiplexer = nil;
	[self performSelector: @selector(_terminate)
				 onThread: self
			   withObject: nil
			waitUntilDone: YES];
	[self cancel];
	[self autorelease];
}

- (void) _addHelper: (AQLowMemoryDownloadHelper *) helper
{
	@synchronized(_downloadHelpers)
	{
		[_downloadHelpers addObject: helper];
	}
	
	[helper start];
}

- (void) _removeHelper: (AQLowMemoryDownloadHelper *) helper
{
	@synchronized(_downloadHelpers)
	{
		[_downloadHelpers removeObject: helper];
	}
}

- (void) _cancelTransfers
{
	@synchronized(_downloadHelpers)
	{
		[_downloadHelpers makeObjectsPerformSelector: @selector(cancel)];
		[_downloadHelpers removeAllObjects];
	}
}

- (void) _terminate
{
	[self _cancelTransfers];
}

- (void) main
{
	NSAutoreleasePool * rootPool = [[NSAutoreleasePool alloc] init];
	
	do
	{
		NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
		[[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode beforeDate: [NSDate distantFuture]];
		[pool drain];
		
	} while ( [self isCancelled] == NO );
	
	[rootPool drain];
}

@end
