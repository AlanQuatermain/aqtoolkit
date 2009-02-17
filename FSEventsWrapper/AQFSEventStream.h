/*
 *  AQFSEventStream.h
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

#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>

@protocol AQFSEventStreamDelegate;

@interface AQFSEventStream : NSObject
{
	// FSEventStreamRef doesn't seem to be a real CF object, so we can't assume
	//  it's gc-friendly (i.e. that it implements a finalize method for gc support)
	FSEventStreamRef					_ref;
	id<AQFSEventStreamDelegate>	__weak	_delegate;
}

@property (readonly) FSEventStreamEventId lastEventId;
@property (assign) id<AQFSEventStreamDelegate> __weak delegate;

// starts the event stream on the current thread's runloop in NSRunLoopCommonModes
+ (AQFSEventStream *) startedEventStreamForPaths: (NSSet *) paths;

// access the global default event latency (min time between events)
+ (NSTimeInterval) defaultLatency;
+ (void) setDefaultLatency: (NSTimeInterval) latency;

// get the latest event from the system as a whole
+ (FSEventStreamEventId) currentEventId;

// initialize for given paths, get events occurring since now
- (id) initWithPaths: (NSSet *) paths;

// designated initializer
// initialize for given paths, then fire callbacks for all matching events since supplied event ID
- (id) initWithPaths: (NSSet *) paths since: (FSEventStreamEventId) sinceWhen;

// add/remove runloop source for handling callbacks
- (void) scheduleWithRunLoop: (NSRunLoop *) runloop forMode: (NSString *) mode;
- (void) unscheduleFromRunLoop: (NSRunLoop *) runloop mode: (NSString *) mode;

// stream activity control
- (void) start;
- (void) stop;			// can call -start again later
- (void) invalidate;	// unusable from now on

// force delivery of pending events, regardless of global latency
// parameter forces synchronous flush-- this call will block until all pending events have been flushed
- (void) flushEvents: (BOOL) sync;

@end

// protocol definitions for the delegate

@protocol AQFSEventStreamDelegate <NSObject>

@required

// primitive update routine -- all basic update notifications will come through here
- (void) foldersUpdated: (NSArray *) paths;

@optional

// implement these to get notification of other types of events

// finished getting historical events
- (void) eventHistoryDone;

// a watched path went away (moved/deleted)
- (void) rootPathChanged: (NSString *) path;

// something happened somewhere inside this folder's subfolder hierarchy, but the system
//  doesn't have accurate info (events were dropped). The system has recommended that the
//  API client scan sub-directories of this path to ensure it has latest information.
- (void) scanSubDirs: (NSString *) path;

// A volume was mounted/unmounted somewhere inside a watched path
- (void) volumeMounted: (NSString *) path;
- (void) volumeUnmounted: (NSString *) path;

@end
