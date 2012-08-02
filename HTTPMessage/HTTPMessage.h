/*
 *  HTTPMessage.h
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

#import <Foundation/Foundation.h>

#import <CFNetwork/CFHTTPMessage.h>
#import <CFNetwork/CFHTTPStream.h>

#import "HTTPAuthentication.h"

@interface HTTPMessage : NSObject <NSCopying, NSMutableCopying>
{
	CFHTTPMessageRef _internal;
}

+ (HTTPMessage *) requestMessageWithMethod: (NSString *) method
									   url: (NSURL *) url
								   version: (NSString *) httpVersion;
+ (HTTPMessage *) responseMessageWithHTTPStatus: (NSInteger) statusCode
									description: (NSString *) statusDescription
										version: (NSString *) httpVersion;
+ (HTTPMessage *) responseMessageFromInputStream: (NSInputStream *) stream;

// designated initializer
- (id) initWithCFHTTPMessageRef: (CFHTTPMessageRef) messageRef;
- (id) initAsRequest: (BOOL) isRequest;
- (id) initResponseFromInputStream: (NSInputStream *) stream;

// append data manually
- (BOOL) appendData: (NSData *) messageData;
@property (nonatomic, readonly, getter=isHeaderComplete) BOOL headerComplete;

// general accessors for message properties and values
@property (nonatomic, copy) NSData * body;
@property (nonatomic, readonly, copy) NSDictionary * headerFields;

- (NSString *) valueForHeaderField: (NSString *) fieldName;
- (void) setValue: (NSString *) value forHeaderField: (NSString *) fieldName;

@property (nonatomic, readonly, copy) NSString * requestMethod;
@property (nonatomic, readonly, copy) NSURL * requestURL;

@property (nonatomic, assign) BOOL useGzipEncoding;

- (NSData *) serializedMessage;

@property (nonatomic, readonly, copy) NSString * version;
@property (nonatomic, readonly) BOOL isRequest;

// these return nil for non-response HTTPMessage instances
@property (nonatomic, readonly) NSInteger statusCode;
@property (nonatomic, readonly, copy) NSString * statusLine;

- (BOOL) applyCredentials: (HTTPAuthentication *) auth
				 username: (NSString *) username
				 password: (NSString *) password
					error: (NSError **) error;
- (BOOL) applyCredentialDictionary: (NSDictionary *) credentials
				 forAuthentication: (HTTPAuthentication *) auth
							 error: (NSError **) error;

// if authenticationScheme is nil, uses HTTPAuthenticationSchemeNegotiate
- (BOOL) addAuthenticationForFailureResponse: (HTTPMessage *) failureResponse
									username: (NSString *) username
									password: (NSString *) password
						authenticationScheme: (NSString *) authenticationScheme;

// this also causes the request to be serialized and sent to the server
// the 'opening' of the input stream may take some time, as it will attempt to read the
//  HTTP header in that time; you should use the runloop to wait for the open event to arrive.
// returns nil if the receiver is a response message
- (NSInputStream *) inputStream;

// if you want/need to provide the message body as a stream, here's your lad.
// if the input stream isn't required, just discard it immediately.
- (NSInputStream *) inputStreamUsingStreamedBodyData: (NSInputStream *) bodyStream;

@end

// HTTP version string constants
#define HTTPVersion1_0 ((NSString *)kCFHTTPVersion1_0)
#define HTTPVersion1_1 ((NSString *)kCFHTTPVersion1_1)

// keys for the authentication credentials dictionary
#define HTTPAuthenticationUsernameKey ((NSString *)kCFHTTPAuthenticationUsername)
#define HTTPAuthenticationPasswordKey ((NSString *)kCFHTTPAuthenticationPassword)
#define HTTPAuthenticationAccountDomainKey ((NSString *)kCFHTTPAuthenticationAccountDomain)
