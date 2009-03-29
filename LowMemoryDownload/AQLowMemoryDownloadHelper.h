/*
 *  AQLowMemoryDownloadHelper.h
 *  AQToolkit
 *
 *  Created by Jim Dovey on 29/01/09.
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

// This is the public-facing class. You have two class methods to use and a few properties you
//  can use to retrieve data from an async callback.

#ifdef IPHONEOS_DEPLOYMENT_TARGET
#import <UIKit/UIKit.h>
#else
#import <Foundation/Foundation.h>
#endif

@class AQLowMemoryDownloadHelper;

@protocol AQAuthenticationProvider <NSObject>
@property (readonly) NSString * username;
@property (readonly) NSString * password;
@end

@protocol AQAsyncDownloadDelegate <NSObject>
- (void) downloaderCompletedTask: (AQLowMemoryDownloadHelper *) downloader;
@end

@interface AQLowMemoryDownloadHelper : NSObject
{
	id<AQAuthenticationProvider>	_authProvider;
	id<AQAsyncDownloadDelegate>		_asyncDelegate;
	
	NSString *						_tmpFilePath;
	NSFileHandle *					_tmpFileHandle;
	
	NSURLRequest *					_request;
	NSURLResponse *					_response;
	NSError *						_error;
	BOOL							_complete;
	
	NSURLConnection *				_connection;
	NSThread *						_thread;
	int								_asyncTimeouts;
}

// used to pull attributes from async notifier
@property (readonly, retain) NSData * data;
@property (readonly, retain) NSURLRequest * request;
@property (readonly, retain) NSURLResponse * response;

+ (NSData *) handleSyncRequest: (NSURLRequest *) request
			  withAuthProvider: (id<AQAuthenticationProvider>) provider
					  response: (NSURLResponse **) response
						 error: (NSError **) error;
+ (void) handleAsyncRequest: (NSURLRequest *) request
		   withAuthProvider: (id<AQAuthenticationProvider>) provider
		  notifyingDelegate: (id<AQAsyncDownloadDelegate>) delegate;

@end

// these exist for the multiplexer thread, don't call them yourself
@interface AQLowMemoryDownloadHelper (MultiplexerSupport)
- (void) start;
- (void) cancel;
@end
