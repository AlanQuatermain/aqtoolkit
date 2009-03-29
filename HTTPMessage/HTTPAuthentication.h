/*
 *  HTTPAuthentication.h
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
