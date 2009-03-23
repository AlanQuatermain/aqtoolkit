/*
 *  ASLQuery.m
 *  AQToolkit
 *
 *  Created by Jim Dovey on 31/8/2008.
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

#import "ASLQuery.h"
#import "NSData+Base64.h"

@implementation ASLQuery

- (id) init
{
	// hacky: -[NSObject init] doesn't appear to do anything except return self, and
	//  -[ASLMessage init] creates a 'message' type of aslmsg, which we would otherwise
	//  need to free. So, I'm forgoing the call to [super init] altogether. Fingers crossed...
	_message = asl_new( ASL_TYPE_QUERY );
	return ( self );
}

- (void) setValue: (id) value forKey: (NSString *) key withOperation: (ASLQueryOperation) operation
{
	if ( (value == nil) || ([value isKindOfClass: [NSNull class]]) )
	{
		asl_unset( _message, [key UTF8String] );
		return;
	}
	
	if ( [value isKindOfClass: [NSString class]] )
	{
		asl_set_query( _message, [key UTF8String], [value UTF8String], operation );
	}
	else if ( [value respondsToSelector: @selector(stringValue)] )
	{
		asl_set_query( _message, [key UTF8String], [[value stringValue] UTF8String], operation );
	}
	else if ( [value isKindOfClass: [NSData class]] )
	{
		asl_set_query( _message, [key UTF8String], 
					   [[value base64EncodedString] UTF8String],  operation );
	}
	else
	{
		asl_set_query( _message, [key UTF8String], [[value stringValue] UTF8String], operation );
	}
}

@end
