/*
 *  AQFSEventStream.h
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
