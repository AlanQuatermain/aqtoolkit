/*
 *  ASLogger.m
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

#import "ASLogger.h"

static ASLogger * __defaultLogger = nil;

@implementation ASLogger

@synthesize client=_client;

+ (ASLogger *) defaultLogger
{
	if ( __defaultLogger == nil )
		__defaultLogger = [[self alloc] init];
	return ( __defaultLogger );
}

+ (ASLogger *) loggerWithName: (NSString *) name 
					 facility: (NSString *) facility
					  options: (uint32_t) opts
{
	ASLogger * result = [[self alloc] init];
	[result setName: name facility: facility options: opts];
	return ( [result autorelease] );
}

- (id) init
{
	if ( [super init] == nil )
		return ( nil );
	
	_additionalFiles = [[NSMutableDictionary alloc] init];
	
	// _client stays NULL for now
	
	return ( self );
}

- (void) dealloc
{
	if ( _client != NULL )
		asl_close( _client );
	[_additionalFiles release];
	[super dealloc];
}

- (void) finalize
{
	if ( _client != NULL )
		asl_close( _client );
	[super finalize];
}

- (void) setName: (NSString *) name facility: (NSString *) facility options: (uint32_t) options
{
	if ( _client != NULL )
		asl_close( _client );
	
	_client = asl_open( [name UTF8String], [facility UTF8String], options );
}

- (BOOL) setFilter: (int) filter
{
	if ( _client == NULL )
		return ( NO );
	
	return ( asl_set_filter(_client, filter) == 0 );
}

- (BOOL) log: (NSString *) format level: (int) level, ...
{
	va_list args;
	va_start(args, level);
	NSString * msg = [[NSString alloc] initWithFormat: format arguments: args];
	va_end(args);
	
	BOOL result = (asl_log(_client, NULL, level, [msg UTF8String], NULL) == 0);
	[msg release];
	
	return ( result );
}

- (BOOL) log: (NSString *) format level: (int) level args: (va_list) args
{
	NSString * msg = [[NSString alloc] initWithFormat: format arguments: args];
	BOOL result = (asl_log(_client, NULL, level, [msg UTF8String], NULL) == 0);
	[msg release];
	return ( result );
}

- (BOOL) log: (NSString *) format message: (ASLMessage *) message level: (int) level, ...
{
	va_list args;
	va_start(args, level);
	NSString * msg = [[NSString alloc] initWithFormat: format arguments: args];
	va_end(args);
	
	BOOL result = (asl_log(_client, message.aslmessage, level, [msg UTF8String], NULL) == 0);
	[msg release];
	
	return ( result );
}

- (BOOL) log: (NSString *) format message: (ASLMessage *) message level: (int) level args: (va_list) args
{
	NSString * msg = [[NSString alloc] initWithFormat: format arguments: args];
	BOOL result = (asl_log(_client, message.aslmessage, level, [msg UTF8String], NULL) == 0);
	[msg release];
	return ( result );
}

- (BOOL) logMessage: (ASLMessage *) message
{
	return ( asl_send(_client, message.aslmessage) == 0 );
}

- (BOOL) addLogFile: (NSString *) path
{
	if ( _client == NULL )
		return ( NO );
	
	@synchronized(_additionalFiles)
	{
		if ( [_additionalFiles objectForKey: path] != nil )
			return ( YES );		// should I return NO here ?
		
		NSFileHandle * handle = [NSFileHandle fileHandleForWritingAtPath: path];
		if ( handle == nil )
			return ( NO );
		
		[_additionalFiles setObject: handle forKey: path];
		
		if ( asl_add_log_file(_client, [handle fileDescriptor]) != 0 )
			return ( NO );
	}
	
	return ( YES );
}

- (void) removeLogFile: (NSString *) path
{
	if ( _client == NULL )
		return;
	
	@synchronized(_additionalFiles)
	{
		// this will close & release the file handle
		[_additionalFiles removeObjectForKey: path];
	}
}

- (ASLResponse *) search: (ASLQuery *) query
{
	aslresponse r = asl_search( _client, query.aslmessage );
	return ( [ASLResponse responseWithResponse: r] );
}

@end
