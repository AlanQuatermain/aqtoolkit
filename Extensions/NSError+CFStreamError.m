/*
 *  NSError+CFStreamError.m
 *  AQToolkit
 *
 *  Created by Jim Dovey on 24/03/09.
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

// weak-link symbols from CoreServices/CFNetwork frameworks
#pragma weak kCFStreamErrorDomainMach
#pragma weak kCFStreamErrorDomainNetDB
#pragma weak kCFStreamErrorDomainNetServices
#pragma weak kCFStreamErrorDomainSOCKS
#pragma weak kCFStreamErrorDomainSystemConfiguration
#pragma weak kCFStreamErrorDomainSSL
#pragma weak kCFStreamErrorDomainHTTP
#pragma weak kCFErrorDomainCFNetwork

// the other domains, and the error codes themselves, are enumerated types & therefore aren't linked

#import <Foundation/Foundation.h>
#import <netdb.h>		// for gai_strerror()

#if TARGET_OS_IPHONE
#import <CFNetwork/CFNetwork.h>
#else
#import <CoreServices/CoreServices.h>
#endif

#import "NSError+CFStreamError.h"

@implementation NSError (CFStreamErrorConversion)

+ (NSError *) errorFromCFStreamError: (CFStreamError) streamError
{
	if ( (streamError.domain == 0) && (streamError.error == 0) )
		return ( nil );
	
	NSString * domain = @"CFStreamErrorDomain";
	NSMutableDictionary * userInfo = [[NSMutableDictionary alloc] init];
	NSInteger code = streamError.error;
	
	// Can't use switch; these constants aren't "integer literals", according to the compiler.
	if ( streamError.domain == kCFStreamErrorDomainPOSIX )
	{
		domain = NSPOSIXErrorDomain;
	}
	else if ( streamError.domain == kCFStreamErrorDomainMacOSStatus )
	{
		domain = NSOSStatusErrorDomain;
	}
	else if ( kCFErrorDomainCFNetwork != 0 )	// check for value of weakly-linked symbol
	{
		if ( streamError.domain == kCFStreamErrorDomainMach )
		{
			domain = NSMachErrorDomain;
		}
		else if ( streamError.domain == kCFStreamErrorDomainNetDB )
		{
			domain = (NSString *) kCFErrorDomainCFNetwork;
			[userInfo setObject: [NSString stringWithCString: gai_strerror(code) encoding: NSASCIIStringEncoding]
						 forKey: NSLocalizedDescriptionKey];
			[userInfo setObject: [NSNumber numberWithInt: code]
						 forKey: (NSString *)kCFGetAddrInfoFailureKey];
		}
		else if ( streamError.domain == kCFStreamErrorDomainNetServices )
		{
			domain = @"kCFStreamErrorDomainNetServices";
		}
		else if ( streamError.domain == kCFStreamErrorDomainSOCKS )
		{
			domain = @"kCFStreamErrorDomainSOCKS";
		}
		else if ( streamError.domain == kCFStreamErrorDomainSystemConfiguration )
		{
			domain = @"kCFStreamErrorDomainSystemConfiguration";
		}		
		else if ( streamError.domain == kCFStreamErrorDomainSSL )
		{
			domain = @"kCFStreamErrorDomainSSL";
		}		
		else if ( streamError.domain == kCFStreamErrorDomainHTTP )
		{
			domain = (NSString *) kCFErrorDomainCFNetwork;
			switch ( code )
			{
				case kCFStreamErrorHTTPParseFailure:
					code = kCFErrorHTTPParseFailure;
					break;
					
				case kCFStreamErrorHTTPRedirectionLoop:
					code = kCFErrorHTTPRedirectionLoopDetected;
					break;
					
				case kCFStreamErrorHTTPBadURL:
					code = kCFErrorHTTPBadURL;
					break;
					
				case kCFStreamErrorHTTPAuthenticationTypeUnsupported:
					code = kCFErrorHTTPAuthenticationTypeUnsupported;
					break;
					
				case kCFStreamErrorHTTPAuthenticationBadUserName:
				case kCFStreamErrorHTTPAuthenticationBadPassword:
					code = kCFErrorHTTPBadCredentials;
					break;
					
				default:
					domain = @"kCFStreamErrorDomainHTTP";
					break;
			}
		}
	}
	
    NSError * result = [NSError errorWithDomain: domain code: code userInfo: userInfo];
    [userInfo release];
    
	return ( result );
}

@end
