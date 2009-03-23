/*
 *  ASLogger.m
 *  AQToolkit
 *
 *  Created by Jim Dovey on 27/8/2008.
 *  Copyright (c) 2008 Jim Dovey. Some Rights Reserved.
 *
 *  This work is licensed under a Creative Commons
 *  Attribution License. You are free to use, modify,
 *  and redistribute this work, provided you include
 *  the following disclaimer:
 *
 *    Portions Copyright (c) 2008 Jim Dovey
 *
 *  For license details, see:
 *    http://creativecommons.org/licenses/by/3.0/
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
	
	BOOL result = (asl_log(_client, NULL, level, [msg UTF8String]) == 0);
	[msg release];
	
	return ( result );
}

- (BOOL) log: (NSString *) format level: (int) level args: (va_list) args
{
	NSString * msg = [[NSString alloc] initWithFormat: format arguments: args];
	BOOL result = (asl_log(_client, NULL, level, [msg UTF8String]) == 0);
	[msg release];
	return ( result );
}

- (BOOL) log: (NSString *) format message: (ASLMessage *) message level: (int) level, ...
{
	va_list args;
	va_start(args, level);
	NSString * msg = [[NSString alloc] initWithFormat: format arguments: args];
	va_end(args);
	
	BOOL result = (asl_log(_client, message.aslmessage, level, [msg UTF8String]) == 0);
	[msg release];
	
	return ( result );
}

- (BOOL) log: (NSString *) format message: (ASLMessage *) message level: (int) level args: (va_list) args
{
	NSString * msg = [[NSString alloc] initWithFormat: format arguments: args];
	BOOL result = (asl_log(_client, message.aslmessage, level, [msg UTF8String]) == 0);
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
