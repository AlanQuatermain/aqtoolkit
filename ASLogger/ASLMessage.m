/*
 *  ASLMessage.m
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

#import "ASLMessage.h"
#import "NSObject+Properties.h"
#import "NSData+Base64.h"

// yay for GC & objc_assign_global() !
static NSDateFormatter * __formatter = nil;

// asl.h doesn't define this, grrr....
static const char * levelStrings[] = 
{
	ASL_STRING_EMERG,
	ASL_STRING_ALERT,
	ASL_STRING_CRIT,
	ASL_STRING_ERR,
	ASL_STRING_WARNING,
	ASL_STRING_NOTICE,
	ASL_STRING_INFO,
	ASL_STRING_DEBUG
};

// keep in sync with ASLResponse.m
@interface ASLMessage (ResponseHelper)
- (id) initWithResponseMessage: (aslmsg) message;
@end

@implementation ASLMessage

@synthesize aslmessage=_message;
@dynamic time, host, sender, facility, processID, userID, groupID, level, message;
@dynamic readUID, readGID;

- (id) init
{
	if ( [super init] == nil )
		return ( nil );
	
	_message = asl_new( ASL_TYPE_MSG );
	
	return ( self );
}

- (id) initWithResponseMessage: (aslmsg) message
{
	if ( [super init] == nil )
		return ( nil );
	
	_message = message;
	_nofree = YES;
	
	return ( self );
}

- (void) dealloc
{
	if ( !_nofree )
		asl_free( _message );
	[super dealloc];
}

- (void) finalize
{
	if ( !_nofree )
		asl_free( _message );
	[super finalize];
}

- (void) setNilValueForKey: (NSString *) key
{
	asl_unset( _message, [key UTF8String] );
}

- (void) setValue: (id) value forUndefinedKey: (NSString *) key
{
	if ( (value == nil) || ([value isKindOfClass: [NSNull class]]) )
	{
		asl_unset( _message, [key UTF8String] );
		return;
	}
	
	// filter readonly properties
	// simplest way: if there's a corresponding property, we shouldn't be here, so ignore the call
	if ( [self hasPropertyForKVCKey: key] )
		return;
	
	if ( [value isKindOfClass: [NSString class]] )
	{
		asl_set( _message, [key UTF8String], [value UTF8String] );
	}
	else if ( [value respondsToSelector: @selector(stringValue)] )
	{
		asl_set( _message, [key UTF8String], [[value stringValue] UTF8String] );
	}
	else if ( [value isKindOfClass: [NSData class]] )
	{
		asl_set( _message, [key UTF8String], [[value base64EncodedString] UTF8String] );
	}
	else
	{
		asl_set( _message, [key UTF8String], [[value description] UTF8String] );
	}
}

- (id) valueForUndefinedKey: (NSString *) key
{
	const char * value = asl_get( _message, [key UTF8String] );
	if ( value == NULL )
		return ( nil );
	
	return ( [NSString stringWithUTF8String: value] );
}

- (NSDate *) time
{
	const char * value = asl_get( _message, ASL_KEY_TIME );
	if ( value == NULL )
		return ( nil );
	
	// convert to an NSDate
	if ( __formatter == nil )
	{
		__formatter = [NSDateFormatter new];
		[__formatter setFormatterBehavior: NSDateFormatterBehavior10_4];
		
		// date format is that used by ctime() - Thu Nov 24 18:22:48 1986
		[__formatter setDateFormat: @"EEE MMM dd HH:mm:ss yyyy"];
	}
	
	return ( [__formatter dateFromString: [NSString stringWithUTF8String: value]] );
}

- (NSHost *) host
{
	const char * value = asl_get( _message, ASL_KEY_HOST );
	if ( value == NULL )
		return ( nil );
	
	return ( [NSHost hostWithAddress: [NSString stringWithUTF8String: value]] );
}

- (NSString *) sender
{
	const char * value = asl_get( _message, ASL_KEY_SENDER );
	if ( value == NULL )
		return ( nil );
	
	return ( [NSString stringWithUTF8String: value] );
}

- (void) setSender: (NSString *) sender
{
	asl_set( _message, ASL_KEY_SENDER, [sender UTF8String] );
}

- (NSString *) facility
{
	const char * value = asl_get( _message, ASL_KEY_FACILITY );
	if ( value == NULL )
		return ( nil );
	
	return ( [NSString stringWithUTF8String: value] );
}

- (void) setFacility: (NSString *) facility
{
	asl_set( _message, ASL_KEY_FACILITY, [facility UTF8String] );
}

- (pid_t) processID
{
	const char * value = asl_get( _message, ASL_KEY_PID );
	if ( value == NULL )
		return ( (pid_t) 0 );
	
    uid_t result = 0;
	sscanf( value, "%d", &result );
    return ( result );
}

- (uid_t) userID
{
	const char * value = asl_get( _message, ASL_KEY_UID );
	if ( value == NULL )
		return ( (uid_t) -1 );
	
    uid_t result = 0;
    sscanf( value, "%d", &result );
    return ( result );
}

- (gid_t) groupID
{
	const char * value = asl_get( _message, ASL_KEY_GID );
	if ( value == NULL )
		return ( (gid_t) -1 );
	
    gid_t result = 0;
	sscanf( value, "%d", &result );
    return ( result );
}

- (int) level
{
	const char * value = asl_get( _message, ASL_KEY_UID );
	if ( value == NULL )
		return ( ASL_LEVEL_NOTICE );	// default level
	
	int level;
	for ( level = ASL_LEVEL_EMERG; level < ASL_LEVEL_DEBUG; level++ )
	{
		if ( strcasecmp(value, levelStrings[level]) == 0 )
			break;
	}
	
	// if we didn't locate the string, the result is ASL_LEVEL_DEBUG
	return ( level );
}

- (void) setLevel: (int) level
{
	asl_set( _message, ASL_KEY_LEVEL, levelStrings[level] );
}

- (NSString *) message
{
	const char * value = asl_get( _message, ASL_KEY_MSG );
	if ( value == NULL )
		return ( nil );
	
	return ( [NSString stringWithUTF8String: value] );
}

- (void) setMessage: (NSString *) message
{
	asl_set( _message, ASL_KEY_MSG, [message UTF8String] );
}

- (uid_t) readUID
{
	const char * value = asl_get( _message, "ReadUID" );
	if ( value == NULL )
		return ( (uid_t) -1 );
	
    uid_t result = 0;
	sscanf( value, "%d", &result );
    return ( result );
}

- (void) setReadUID: (uid_t) readUID
{
	char str[12];
	sprintf( str, "%d", (int) readUID );
	asl_set( _message, "ReadUID", str );
}

- (gid_t) readGID
{
	const char * value = asl_get( _message, "ReadGID" );
	if ( value == NULL )
		return ( (gid_t) -1 );
	
    gid_t result = 0;
	sscanf( value, "%d", &result );
    return ( result );
}

- (void) setReadGID: (gid_t) readGID
{
	char str[12];
	sprintf( str, "%d", (int) readGID );
	asl_set( _message, "ReadGID", str );
}

@end
