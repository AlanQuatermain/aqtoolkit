//
//  AQConnectionMultiplexer.h
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

// This is an internal class, designed to reduce memory overhead in multithreaded networking
//  situations by performing all networking on a single background thread, so per-thread data
//  caches are kept to a minimum.

#ifdef IPHONEOS_DEPLOYMENT_TARGET
#import <UIKit/UIKit.h>
#else
#import <Foundation/Foundation.h>
#endif

@class AQLowMemoryDownloadHelper;

@interface AQConnectionMultiplexer : NSThread
{
	NSMutableSet *			_downloadHelpers;
	BOOL					_runThread;
}

+ (void) attachDownloadHelper: (AQLowMemoryDownloadHelper *) helper;

@end
