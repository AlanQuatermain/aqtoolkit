/*
 *  FSEvent.h
 *  AQToolkit
 *
 *  Created by Jim Dovey on 19/02/2009.
 *  Copyright (c) 2009 Jim Dovey. Some Rights Reserved.
 *
 *  This work is licensed under a Creative Commons
 *  Attribution License. You are free to use, modify,
 *  and redistribute this work, provided you include
 *  the following disclaimer:
 *
 *    Portions Copyright (c) 2009 Jim Dovey
 *
 *  For license details, see:
 *    http://creativecommons.org/licenses/by/3.0/
 *
 */

#import <Foundation/Foundation.h>
#import "fsevents.h"

enum
{
	FSEventInvalid				= FSE_INVALID,
	FSEventCreateFile			= FSE_CREATE_FILE,
	FSEventDelete				= FSE_DELETE,
	FSEventStateChanged			= FSE_STAT_CHANGED,
	FSEventRename				= FSE_RENAME,
	FSEventContentModified		= FSE_CONTENT_MODIFIED,
	FSEventExchange				= FSE_EXCHANGE,
	FSEventFinderInfoChanged	= FSE_FINDER_INFO_CHANGED,
	FSEventCreateFolder			= FSE_CREATE_DIR,
	FSEventChangeOwner			= FSE_CHOWN,
	FSEventXAttrModified		= FSE_XATTR_MODIFIED,
	FSEventXAttrRemoved			= FSE_XATTR_REMOVED
	
};
typedef NSInteger FSEventCode;

@interface FSEvent : NSObject
{
	FSEventCode				_eventCode;
	pid_t					_processID;
	u_int64_t				_timestamp;
	NSMutableDictionary *	_arguments;
}

@property (nonatomic) FSEventCode eventCode;
@property (nonatomic) pid_t processID;
@property (nonatomic) u_int64_t timestamp;
@property (nonatomic, readonly, copy) NSDictionary * arguments;

// returns a description for the given event
+ (NSString *) stringForEventCode: (FSEventCode) code;

@end
