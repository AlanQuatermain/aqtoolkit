/*
 *  ASLogger.h
 *  AQToolkit
 *
 *  Created by Jim Dovey on 27/8/2008.
 *
 *  Copyright (c) 2008-2009, Jim Dovey
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

#pragma mark -

// some useful macros to help cure excessively-large-code-level-verbosity complex
// note that these all operate on the default logger. If you need something more specific,
//  you'll have to put up with a little verbosity.
#define ASLog(lvl, format, ...) [[ASLogger defaultLogger] log: format level: lvl , ##__VA_ARGS__]
#define ASLogMessage(lvl, msg, format, ...) [[ASLogger defaultLogger] log: format message: msg level: lvl , ##__VA_ARGS__]

#define ASLogDebug(format, ...)		ASLog(ASL_LEVEL_DEBUG, format , ##__VA_ARGS__)
#define ASLogInfo(format, ...)		ASLog(ASL_LEVEL_INFO, format , ##__VA_ARGS__)
#define ASLogNotice(format, ...)	ASLog(ASL_LEVEL_NOTICE, format , ##__VA_ARGS__)
#define ASLogWarning(format, ...)	ASLog(ASL_LEVEL_WARNING, format , ##__VA_ARGS__)
#define ASLogError(format, ...)		ASLog(ASL_LEVEL_ERR, format , ##__VA_ARGS__)
#define ASLogCritical(format, ...)	ASLog(ASL_LEVEL_CRIT, format , ##__VA_ARGS__)
#define ASLogAlert(format, ...)		ASLog(ASL_LEVEL_ALERT, format , ##__VA_ARGS__)
#define ASLogEmergency(format, ...)	ASLog(ASL_LEVEL_EMERG, format , ##__VA_ARGS__)
