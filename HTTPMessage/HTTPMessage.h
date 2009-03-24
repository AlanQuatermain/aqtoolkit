/*
 *  HTTPMessage.h
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

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <CFNetwork/CFHTTPMessage.h>
#else
#import <CoreServices/../Frameworks/CFNetwork.framework/Headers/CFHTTPMessage.h>
#endif

#import "HTTPAuthentication.h"

@interface HTTPMessage : NSObject <NSCopying, NSMutableCopying>
{
	CFHTTPMessageRef __strong	_internal;
}

+ (HTTPMessage *) requestMessageWithMethod: (NSString *) method
									   url: (NSURL *) url
								   version: (NSString *) httpVersion;
+ (HTTPMessage *) responseMessageWithHTTPStatus: (NSInteger) statusCode
									description: (NSString *) statusDescription
										version: (NSString *) httpVersion;

// designated initializer
- (id) initWithCFHTTPMessageRef: (CFHTTPMessageRef) messageRef;
- (id) initAsRequest: (BOOL) isRequest;

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

@end

// HTTP version string constants
#define HTTPVersion1_0 ((NSString *)kCFHTTPVersion1_0)
#define HTTPVersion1_1 ((NSString *)kCFHTTPVersion1_1)

// keys for the authentication credentials dictionary
#define HTTPAuthenticationUsernameKey ((NSString *)kCFHTTPAuthenticationUsername)
#define HTTPAuthenticationPasswordKey ((NSString *)kCFHTTPAuthenticationPassword)
#define HTTPAuthenticationAccountDomainKey ((NSString *)kCFHTTPAuthenticationAccountDomain)
