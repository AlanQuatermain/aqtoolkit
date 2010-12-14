//
//  AQXMLParserWithTimeout.m
//  Kobov3
//
//  Created by Jim Dovey on 10-04-08.
//  Copyright 2010 Kobo Inc. All rights reserved.
//

#import "AQXMLParserWithTimeout.h"
#import "AQXMLParserInternal.h"

const NSTimeInterval KBDefaultXMLParserTimeout = 45.0;

@interface AQXMLParser ()
- (void) _setStreamComplete:(BOOL)parsedOK;
@end

@implementation AQXMLParserWithTimeout

@synthesize timeout=_timeoutInterval;

- (void) dealloc
{
	[_timeoutTimer invalidate];
	[_timeoutTimer release];
	[super dealloc];
}

- (void) setTimeout: (NSTimeInterval) aTimeout
{
	if ( aTimeout == _timeoutInterval )
		return;
	
	_timeoutInterval = aTimeout;
	
	if ( _timeoutInterval == 0.0 )
	{
		[_timeoutTimer invalidate];
		[_timeoutTimer release];
		_timeoutTimer = nil;
		return;
	}
	
	if ( _timeoutTimer != nil )
	{
		[_timeoutTimer setFireDate: [NSDate dateWithTimeIntervalSinceNow: _timeoutInterval]];
	}
}

- (void) stream: (NSStream *) stream handleEvent: (NSStreamEvent) streamEvent
{
	if ( _timeoutTimer != nil )
		[_timeoutTimer setFireDate: [NSDate dateWithTimeIntervalSinceNow: _timeoutInterval]];
	
	switch ( streamEvent )
	{
		case NSStreamEventErrorOccurred:
		case NSStreamEventEndEncountered:
			[_timeoutTimer invalidate];
			break;
			
		default:
			break;
	}
	
	[super stream: stream handleEvent: streamEvent];
}

- (BOOL) parseAsynchronouslyUsingRunLoop: (NSRunLoop *) runloop
									mode: (NSString *) mode
					   notifyingDelegate: (id) asyncCompletionDelegate
								selector: (SEL) completionSelector
								 context: (void *) contextPtr
{
	if ( [super parseAsynchronouslyUsingRunLoop: runloop
										   mode: mode
							  notifyingDelegate: asyncCompletionDelegate
									   selector: completionSelector
										context: contextPtr] == NO )
	{
		return ( NO );
	}
	
	if ( _timeoutInterval != 0.0 )
	{
		_timeoutTimer = [[NSTimer alloc] initWithFireDate: [NSDate dateWithTimeIntervalSinceNow: _timeoutInterval]
												 interval: _timeoutInterval
												   target: self
												 selector: @selector(_timeoutFired:)
												 userInfo: nil
												  repeats: NO];
		[runloop addTimer: _timeoutTimer forMode: mode];
	}
	
	return ( YES );
}

- (void) _timeoutFired: (NSTimer *) timer
{
	[_stream close];
	_internal->error = [[NSError alloc] initWithDomain: NSCocoaErrorDomain code: NSURLErrorTimedOut userInfo: nil];
	if ( [_delegate respondsToSelector: @selector(parser:parseErrorOccurred:)] )
		[_delegate parser: self parseErrorOccurred: _internal->error];
	[self _setStreamComplete: NO];
}

@end
