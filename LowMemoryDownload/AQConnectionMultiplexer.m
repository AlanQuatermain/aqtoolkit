//
//  AQConnectionMultiplexer.m
//  AQToolkit
//
//  Created by Jim Dovey on 29/01/09.
//  Copyright (c) 2009 Jim Dovey. Some Rights Reserved.
//  This work is licensed under a Creative Commons  Attribution License. You are free to use, modify,
//  and redistribute this work, but may only distribute
//  the resulting work under the same, similar or a
//  compatible license. In addition, you must include
//  the following disclaimer:
//
//    Portions Copyright (c) 2009 Jim Dovey
//
//  For license details, see:
//    http://creativecommons.org/licenses/by-sa/3.0/
//
//

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
		
		[__connectionMultiplexer performSelector: @selector(_addHelper:)
										onThread: __connectionMultiplexer
									  withObject: helper
								   waitUntilDone: YES];
	}
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

- (void) _terminate
{
	[_downloadHelpers makeObjectsPerformSelector: @selector(cancel)];
}

- (void) _addHelper: (AQLowMemoryDownloadHelper *) helper
{
	[_downloadHelpers addObject: helper];
	[helper start];
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
