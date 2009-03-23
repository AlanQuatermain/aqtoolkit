//
//  AQConnectionMultiplexer.h
//  AQToolkit
//
//  Created by Jim Dovey on 29/01/09.
//  Copyright (c) 2009 Jim Dovey. Some Rights Reserved.
//  
//  This work is licensed under a Creative Commons 
//  Attribution License. You are free to use, modify,
//  and redistribute this work, provided you include
//  the following disclaimer:
//
//    Portions Copyright (c) 2009 Jim Dovey
//
//  For license details, see:
//    http://creativecommons.org/licenses/by/3.0/
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
+ (void) removeDownloadHelper: (AQLowMemoryDownloadHelper *) helper;
+ (void) cancelPendingTransfers;

@end
