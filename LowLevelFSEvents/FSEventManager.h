/*
 *  FSEventManager.h
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

#import <Foundation/Foundation.h>

@class FSEvent;
@protocol FSEventHandler;

@interface FSEventManager : NSObject
{
	int							_descriptor;
	id<FSEventHandler> __weak	_handler;
	NSConditionLock *			_threadStateLock;
}

@property (nonatomic, assign) id<FSEventHandler> __weak handler;

+ (FSEventManager *) sharedManager;
+ (void) shutdown;

@end

@protocol FSEventHandler
- (void) handleEvent: (FSEvent *) event;
@end
