//
//  AQLowMemoryDownloadHelper.h
//  AQToolkit
//
//  Created by Jim Dovey on 29/01/09.
//  Copyright (c) 2009 Jim Dovey. Some Rights Reserved.
//  This work is licensed under a Creative Commons  Attribution License. You are free to use, modify,
//  and redistribute this work, but may only distribute
//  the resulting work under the same, similar or a
//  compatible license. In addition, you must include
//  the following disclaimer:
//
//    Portions Copyright (c) 2009 Jim Dovey
//
//  For license details, see:
//    http://creativecommons.org/licenses/by-sa/3.0/
//

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
