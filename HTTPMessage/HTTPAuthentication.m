/*
 *  HTTPAuthentication.m
 *  AQToolkit
 *
 *  Created by Jim Dovey on 23/3/2009.
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

#import "HTTPAuthentication.h"
#import "HTTPMessage.h"
#import "HTTPMessageInternalAccess.h"

@implementation HTTPAuthentication (InternalAccess)

- (CFHTTPAuthenticationRef) internalRef
{
	return ( _internal );
}

@end

@implementation HTTPAuthentication

+ (HTTPAuthentication *) authenticationFromResponse: (HTTPMessage *) responseMessage
{
	return ( [[[self allocWithZone: [responseMessage zone]] initWithHTTPResponse: responseMessage] autorelease] );
}

- (id) initWithHTTPResponse: (HTTPMessage *) responseMessage
{
	if ( [super init] == nil )
		return ( nil );
	
	_internal = CFHTTPAuthenticationCreateFromResponse( kCFAllocatorDefault, responseMessage.internalRef );
	if ( _internal == NULL )
	{
		[self release];
		return ( nil );
	}
	
	CFMakeCollectable( _internal );
	
	return ( self );
}

- (void) dealloc
{
	if ( _internal != NULL )
		CFRelease( _internal );
	
	[super dealloc];
}

- (BOOL) appliesToRequest: (HTTPMessage *) requestMessage
{
	return ( CFHTTPAuthenticationAppliesToRequest(_internal, requestMessage.internalRef) );
}

- (NSArray *) domains
{
	NSArray * result = (NSArray *) NSMakeCollectable( CFHTTPAuthenticationCopyDomains(_internal) );
	return ( [result autorelease] );
}

- (NSString *) method
{
	NSString * result = (NSString *) NSMakeCollectable( CFHTTPAuthenticationCopyMethod(_internal) );
	return ( [result autorelease] );
}

- (NSString *) realm
{
	NSString * result = (NSString *) NSMakeCollectable( CFHTTPAuthenticationCopyRealm(_internal) );
	return ( [result autorelease] );
}

- (BOOL) isValid
{
	return ( CFHTTPAuthenticationIsValid(_internal, NULL) );
}

- (NSInteger) authenticationError
{
	CFStreamError error;
	if ( CFHTTPAuthenticationIsValid(_internal, &error) )
		return ( 0 );
	
	return ( error.error );
}

- (BOOL) requiresAccountDomain
{
	return ( CFHTTPAuthenticationRequiresAccountDomain(_internal) );
}

- (BOOL) requiresUsernameAndPassword
{
	return ( CFHTTPAuthenticationRequiresUserNameAndPassword(_internal) );
}

@end
