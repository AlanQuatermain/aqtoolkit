/*
 *  ASLMessage.m
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
/*
 * Provided under non-exclusive license to Tenzing Communications.
 */

#import "ASLMessage.h"
#import "NSObject+Properties.h"

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

- (void) dealloc
{
	asl_free( _message );
	[super dealloc];
}

- (void) finalize
{
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
	
	if ( class_getProperty([self class], [name UTF8String]) != NULL )
		return;
	
	if ( [value isKindOfClass: [NSString class]] )
	{
		asl_set( _message, [key UTF8String], [value UTF8String] );
	}
	else if ( [value respondsToSelector: @selector(stringValue)] )
	{
		asl_set( _message, [key UTF8String], [[value stringValue] UTF8String] );
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
	
	return ( (uid_t) sscanf(value, "%d") );
}

- (uid_t) userID
{
	const char * value = asl_get( _message, ASL_KEY_UID );
	if ( value == NULL )
		return ( (uid_t) -1 );
	
	return ( (uid_t) sscanf(value, "%d") );
}

- (gid_t) groupID
{
	const char * value = asl_get( _message, ASL_KEY_GID );
	if ( value == NULL )
		return ( (gid_t) -1 );
	
	return ( (gid_t) sscanf(value, "%d") );
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
	
	return ( (uid_t) sscanf(value, "%d") );
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
	
	return ( (gid_t) sscanf(value, "%d") );
}

- (void) setReadGID: (gid_t) readGID
{
	char str[12];
	sprintf( str, "%d", (int) readGID )
	asl_set( _message, "ReadGID", str );
}

@end
