/*
 *  HTTPAuthentication.h
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
#import <CFNetwork/CFHTTPAuthentication.h>
#else
#import <CoreServices/../Frameworks/CFNetwork.framework/Headers/CFHTTPAuthentication.h>
#endif

@class HTTPMessage;

@interface HTTPAuthentication : NSObject
{
	CFHTTPAuthenticationRef __strong	_internal;
}

+ (HTTPAuthentication *) authenticationFromResponse: (HTTPMessage *) responseMessage;
- (id) initWithHTTPResponse: (HTTPMessage *) responseMessage;

- (BOOL) appliesToRequest: (HTTPMessage *) requestMessage;

@property (nonatomic, readonly, copy) NSArray * domains;
@property (nonatomic, readonly, copy) NSString * method;
@property (nonatomic, readonly, copy) NSString * realm;

@property (nonatomic, readonly, getter=isValid) BOOL valid;
@property (nonatomic, readonly) NSInteger authenticationError;
@property (nonatomic, readonly) BOOL requiresAccountDomain;
@property (nonatomic, readonly) BOOL requiresUsernameAndPassword;

@end

// Authentication error constants
enum
{
	HTTPAuthenticationErrorUnsupportedType	= kCFStreamErrorHTTPAuthenticationTypeUnsupported,
	HTTPAuthenticationErrorBadUserName		= kCFStreamErrorHTTPAuthenticationBadUserName,
	HTTPAuthenticationErrorBadPassword		= kCFStreamErrorHTTPAuthenticationBadPassword
	
};

// Authentication scheme constants
#define HTTPAuthenticationSchemeBasic ((NSString *)kCFHTTPAuthenticationSchemeBasic)
#define HTTPAuthenticationSchemeDigest ((NSString *)kCFHTTPAuthenticationSchemeDigest)
#define HTTPAuthenticationSchemeNTLM ((NSString *)kCFHTTPAuthenticationSchemeNTLM)
#define HTTPAuthenticationSchemeNegotiate ((NSString *)kCFHTTPAuthenticationSchemeNegotiate)
