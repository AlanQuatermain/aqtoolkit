/*
 *  ASLogger.h
 *  AQToolkit
 *
 *  Created by Jim Dovey on 27/8/2008.
 *  Copyright (c) 2008 Jim Dovey. Some Rights Reserved.
 *
 *  This work is licensed under a Creative Commons
 *  Attribution License. You are free to use, modify,
 *  and redistribute this work, but may only distribute
 *  the resulting work under the same, similar or a
 *  compatible license. In addition, you must include
 *  the following disclaimer:
 *
 *    Portions Copyright (c) 2008 Jim Dovey
 *
 *  For license details, see:
 *    http://creativecommons.org/licenses/by-sa/3.0/
 *
 */

#import <Foundation/Foundation.h>
#import <asl.h>

#import "ASLMessage.h"
#import "ASLQuery.h"
#import "ASLResponse.h"

@interface ASLogger : NSObject
{
	aslclient				_client;
	NSMutableDictionary *	_additionalFiles;
}

@property (nonatomic, readonly) aslclient client;

// returns a singleton using default parameters -- this does not open a client connection
//  by default, and thus may be initialized using setName:facility:options: upon application
//  startup, and future users of the logger can simply call [ASLogger defaultLogger] with impunity
+ (ASLogger *) defaultLogger;

+ (ASLogger *) loggerWithName: (NSString *) name
					 facility: (NSString *) facility
					  options: (uint32_t) opts;

// This will close and reopen an existing logger connection, if necessary.
// Any previously created messages will stay around.
- (void) setName: (NSString *) name facility: (NSString *) facility options: (uint32_t) options;

// setting which log levels to use -- requires that a connection be opened via -setName:faciity:options:
- (BOOL) setFilter: (int) filter;

// basic message senders:
- (BOOL) log: (NSString *) format level: (int) level, ...;
- (BOOL) log: (NSString *) format level: (int) level args: (va_list) args;

// enhanced message senders -- for using precomposed ASL message structures with new formats
- (BOOL) log: (NSString *) format message: (ASLMessage *) message level: (int) level, ...;
- (BOOL) log: (NSString *) format message: (ASLMessage *) message level: (int) level args: (va_list) args;

// use this when you've set everything you need in the ASLMessage already
- (BOOL) logMessage: (ASLMessage *) message;

// Logging to external files. Read the asl manual for information on the format of these files.
// These require that an explicit connection be opened using -setName:facility:options:
// The receiver will manage the file descriptors for each provided path. If you want to specify
//  a descriptor without a path, call asl_add_log_file() and asl_remove_log_file() manually on
//  the receiver's 'client' property.
- (BOOL) addLogFile: (NSString *) path;
- (void) removeLogFile: (NSString *) path;

// searching the database: setup an ASLQuery and pass it here. You can fetch found messages
//  from the returned ASLResponse object
- (ASLResponse *) search: (ASLQuery *) query;

@end
