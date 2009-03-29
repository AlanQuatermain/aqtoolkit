/*
 *  HTTPAuthentication.m
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
