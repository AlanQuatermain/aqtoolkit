/*
 *  HTTPMessage.m
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

#import "HTTPMessage.h"
#import "HTTPAuthentication.h"
#import "HTTPMessageInternalAccess.h"
#import "NSError+CFStreamError.h"

#if TARGET_OS_IPHONE
#import <CFNetwork/CFNetwork.h>
#else
#import <CoreServices/CoreServices.h>
#endif

@implementation HTTPMessage (InternalAccess)

- (CFHTTPMessageRef) internalRef
{
	return ( _internal );
}

@end

@implementation HTTPMessage

+ (HTTPMessage *) requestMessageWithMethod: (NSString *) method
									   url: (NSURL *) url
								   version: (NSString *) httpVersion
{
	CFHTTPMessageRef message = CFHTTPMessageCreateRequest( kCFAllocatorDefault, (CFStringRef)method,
														   (CFURLRef)url, (CFStringRef)httpVersion );
	return ( [[[self alloc] initWithCFHTTPMessageRef: message] autorelease] );
}

+ (HTTPMessage *) responseMessageWithHTTPStatus: (NSInteger) statusCode
									description: (NSString *) statusDescription
										version: (NSString *) httpVersion
{
	CFHTTPMessageRef message = CFHTTPMessageCreateResponse( kCFAllocatorDefault, (CFIndex)statusCode,
														    (CFStringRef)statusDescription, (CFStringRef)httpVersion );
	return ( [[[self alloc] initWithCFHTTPMessageRef: message] autorelease] );
}

- (id) initWithCFHTTPMessageRef: (CFHTTPMessageRef) message
{
	if ( message == NULL )
		return ( nil );
	
	if ( [super init] == nil )
		return ( nil );
	
	_internal = (CFHTTPMessageRef) CFMakeCollectable( message );
	
	return ( self );
}

- (id) initAsRequest: (BOOL) asRequest
{
	CFHTTPMessageRef message = CFHTTPMessageCreateEmpty( kCFAllocatorDefault, asRequest );
	return ( [self initWithCFHTTPMessageRef: message] );
}

- (void) dealloc
{
	if ( _internal != NULL )
		CFRelease( _internal );
	
	[super dealloc];
}

- (id) copyWithZone: (NSZone *) zone
{
	CFHTTPMessageRef newMessage = CFHTTPMessageCreateCopy( kCFAllocatorDefault, _internal );
	return ( [[HTTPMessage allocWithZone: zone] initWithCFHTTPMessageRef: newMessage] );
}

- (id) mutableCopyWithZone: (NSZone *) zone
{
	return ( [self copyWithZone: zone] );
}

- (BOOL) appendData: (NSData *) messageData
{
	return ( CFHTTPMessageAppendBytes(_internal, (const UInt8 *)[messageData bytes], (CFIndex)[messageData length]) );
}

- (BOOL) isHeaderComplete
{
	return ( CFHTTPMessageIsHeaderComplete(_internal) );
}

- (NSData *) body
{
	NSData * body = (NSData *) NSMakeCollectable( CFHTTPMessageCopyBody(_internal) );
	return ( [body autorelease] );
}

- (void) setBody: (NSData *) body
{
	CFHTTPMessageSetBody( _internal, (CFDataRef)body );
}

- (NSDictionary *) headerFields
{
	NSDictionary * allHeaderFields = (NSDictionary *) NSMakeCollectable( CFHTTPMessageCopyAllHeaderFields(_internal) );
	return ( [allHeaderFields autorelease] );
}

- (NSString *) valueForHeaderField: (NSString *) fieldName
{
	NSString * value = (NSString *) NSMakeCollectable( CFHTTPMessageCopyHeaderFieldValue(_internal, (CFStringRef)fieldName) );
	return ( [value autorelease] );
}

- (void) setValue: (NSString *) value forHeaderField: (NSString *) fieldName
{
	CFHTTPMessageSetHeaderFieldValue( _internal, (CFStringRef)fieldName, (CFStringRef)value );
}

- (NSString *) requestMethod
{
	NSString * method = (NSString *) NSMakeCollectable( CFHTTPMessageCopyRequestMethod(_internal) );
	return ( [method autorelease] );
}

- (NSURL *) requestURL
{
	NSURL * url = (NSURL *) NSMakeCollectable( CFHTTPMessageCopyRequestURL(_internal) );
	return ( [url autorelease] );
}

- (NSData *) serializedMessage
{
	NSData * data = (NSData *) NSMakeCollectable( CFHTTPMessageCopySerializedMessage(_internal) );
	return ( [data autorelease] );
}

- (NSString *) version
{
	NSString * version = (NSString *) NSMakeCollectable( CFHTTPMessageCopyVersion(_internal) );
	return ( [version autorelease] );
}

- (BOOL) isRequest
{
	return ( CFHTTPMessageIsRequest(_internal) );
}

- (NSInteger) statusCode
{
	if ( self.isRequest )
		return ( 0 );
	
	return ( (NSInteger) CFHTTPMessageGetResponseStatusCode(_internal) );
}

- (NSString *) statusLine
{
	if ( self.isRequest )
		return ( nil );
	
	NSString * status = (NSString *) NSMakeCollectable( CFHTTPMessageCopyResponseStatusLine(_internal) );
	return ( [status autorelease] );
}

- (BOOL) applyCredentials: (HTTPAuthentication *) auth
				 username: (NSString *) username
				 password: (NSString *) password
					error: (NSError **) error
{
	CFStreamError streamError;
	Boolean result = CFHTTPMessageApplyCredentials( _internal, auth.internalRef, (CFStringRef)username,
												    (CFStringRef)password, &streamError );
	if ( (result == FALSE) && (error != NULL) )
		*error = [NSError errorFromCFStreamError: streamError];
	
	return ( (BOOL) result );
}

- (BOOL) applyCredentialDictionary: (NSDictionary *) credentials
				 forAuthentication: (HTTPAuthentication *) auth
							 error: (NSError **) error
{
	CFStreamError streamError;
	Boolean result = CFHTTPMessageApplyCredentialDictionary( _internal, auth.internalRef, (CFDictionaryRef)credentials,
															 &streamError );
	if ( (result == FALSE) && (error != NULL) )
		*error = [NSError errorFromCFStreamError: streamError];
	
	return ( (BOOL) result );
}

- (BOOL) addAuthenticationForFailureResponse: (HTTPMessage *) failureResponse
									username: (NSString *) username
									password: (NSString *) password
						authenticationScheme: (NSString *) authenticationScheme
{
	Boolean forProxy = (failureResponse.statusCode == 407);
	return ( CFHTTPMessageAddAuthentication(_internal, failureResponse.internalRef, (CFStringRef)username,
											(CFStringRef)password, (CFStringRef)authenticationScheme, forProxy) );
}

- (NSInputStream *) inputStream
{
	if ( self.isRequest == NO )
		return ( nil );
	
	NSInputStream * result = NSMakeCollectable( CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, _internal) );
	return ( [result autorelease] );
}

@end
