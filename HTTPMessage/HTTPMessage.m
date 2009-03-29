/*
 *  HTTPMessage.m
 *  AQToolkit
 *
 *  Created by Jim Dovey on 23/3/2009.
 *
 *  Copyright (c) 2009, Jim Dovey
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

- (NSInputStream *) inputStreamUsingStreamedBodyData: (NSInputStream *) bodyStream
{
	if ( self.isRequest == NO )
		return ( nil );
	
	NSInputStream * result = NSMakeCollectable( CFReadStreamCreateForStreamedHTTPRequest(kCFAllocatorDefault, _internal, (CFReadStreamRef)bodyStream) );
	return ( [result autorelease] );
}

@end
