//
//  AQLowMemoryDownloadHelper.m
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
//

#import "AQLowMemoryDownloadHelper.h"
#import "AQConnectionMultiplexer.h"
#import <sys/syslimits.h>

@interface AQLowMemoryDownloadHelper (Private)
- (BOOL) _performSynchronousRequest: (NSURLRequest *) request;
- (void) _performAsynchronousRequest: (NSURLRequest *) request;
- (void) connection: (NSURLConnection *) connection 
didReceiveAuthenticationChallenge: (NSURLAuthenticationChallenge *) challenge;
- (void) connection: (NSURLConnection *) connection didReceiveResponse: (NSURLResponse *) response;
- (void) connection: (NSURLConnection *) connection didReceiveData: (NSData *) data;
- (void) connectionDidFinishLoading: (NSURLConnection *) connection;
- (void) connection: (NSURLConnection *) connection didFailWithError: (NSError *) error;
- (NSCachedURLResponse *) connection: (NSURLConnection *) connection
				   willCacheResponse: (NSCachedURLResponse *) cachedResponse;
@end

@interface AQLowMemoryDownloadHelper ()
@property (retain) id<AQAuthenticationProvider> authProvider;
@property (retain) id<AQAsyncDownloadDelegate> asyncDelegate;
@property (retain) NSURLResponse * response;
@property (assign) BOOL complete;
@property (retain) NSError * error;
@property (retain) NSURLConnection * connection;
@property (retain) NSURLRequest * request;
@end

@implementation AQLowMemoryDownloadHelper

@synthesize authProvider=_authProvider;
@synthesize asyncDelegate=_asyncDelegate;
@dynamic data;
@synthesize response=_response;
@synthesize error=_error;
@synthesize complete=_complete;
@synthesize connection=_connection;
@synthesize request=_request;

+ (NSData *) handleSyncRequest: (NSURLRequest *) request
			  withAuthProvider: (id<AQAuthenticationProvider>) provider
					  response: (NSURLResponse **) response
						 error: (NSError **) error
{
	AQLowMemoryDownloadHelper * obj = [[AQLowMemoryDownloadHelper alloc] init];
	obj.authProvider = provider;
	
	int tries = 0;
	BOOL ok = NO;
	
	while ( (!ok) && (tries++ < 3) )
	{
		ok = [obj _performSynchronousRequest: request];
		if ( !ok )
		{
			NSError * err = obj.error;
			if ( ([[err domain] isEqualToString: NSURLErrorDomain]) &&
				 ([err code] == NSURLErrorTimedOut) )
			{
				continue;
			}
		}
		
		break;
	}
	
	if ( response != NULL )
		*response = obj.response;
	if ( error != NULL )
		*error = obj.error;
	
	NSData * result = nil;
	if ( ok )
		result = obj.data;
	
	[obj release];
	
	return ( result );
}

+ (void) handleAsyncRequest: (NSURLRequest *) request
		   withAuthProvider: (id<AQAuthenticationProvider>) provider
		  notifyingDelegate: (id<AQAsyncDownloadDelegate>) delegate
{
	AQLowMemoryDownloadHelper * obj = [[AQLowMemoryDownloadHelper alloc] init];
	obj.authProvider = provider;
	obj.asyncDelegate = delegate;
	
	[obj _performAsynchronousRequest: request];
}

- (id) init
{
	if ( [super init] == nil )
		return ( nil );
	
	// downloaded daa gets offloaded to the filesystem immediately, to get it out of memory
	NSString * path = [NSTemporaryDirectory() stringByAppendingPathComponent: @"Quatermain"];
	[[NSFileManager defaultManager] createDirectoryAtPath: path attributes: nil];
	
	char buf[PATH_MAX];
	[path getCString: buf maxLength: PATH_MAX encoding: NSASCIIStringEncoding];
	strlcat( buf, "/tmp.XXXXXX", PATH_MAX );
	
	int fd = mkstemp( buf );
	_tmpFilePath = [[NSString alloc] initWithCString: buf encoding: NSASCIIStringEncoding];
	_tmpFileHandle = [[NSFileHandle alloc] initWithFileDescriptor: fd closeOnDealloc: YES];
	
	return ( self );
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[_authProvider release];
	[_asyncDelegate release];
	[_tmpFilePath release];
	[_tmpFileHandle release];
	[_request release];
	[_response release];
	[_error release];
	[_connection release];
	[super dealloc];
}

- (void) _cancel
{
	[self.connection cancel];
	[_tmpFilePath release];
	_tmpFilePath = nil;
	self.complete = YES;
}

- (NSData *) data
{
	if ( _tmpFilePath == nil )
		return ( nil );
	
	// we return memory-mapped data, so the kernel can take over management of large data blobs
	return ( [NSData dataWithContentsOfMappedFile: _tmpFilePath] );
}

@end

@implementation AQLowMemoryDownloadHelper (MultiplexerSupport)

- (void) start
{
	NSURLConnection * conn = [[NSURLConnection alloc] initWithRequest: _request
															 delegate: self];
	self.connection = conn;
	[conn release];
}

- (void) cancel
{
	[self _cancel];
}

@end

@implementation AQLowMemoryDownloadHelper (Private)

- (BOOL) _performSynchronousRequest: (NSURLRequest *) request
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	// set iPhone network activity indicator here if desired
	
	self.complete = NO;
	self.request = request;
	_thread = [NSThread currentThread];	// remember which thread is blocking on the network I/O
	
	// we'll add to the multiplexer thread when we return to the runloop
	[AQConnectionMultiplexer performSelector: @selector(attachDownloadHelper:)
								  withObject: self
								  afterDelay: 0.0];
	
	// if running on main thread, we want to keep running in the current (event-tracking)
	//  runloop mode
	NSString * mode = [[NSRunLoop currentRunLoop] currentMode];
	if ( mode == nil )
		mode = NSDefaultRunLoopMode;
	
	// now wait for completion signal
	do
	{
		NSAutoreleasePool * loop = [[NSAutoreleasePool alloc] init];
		BOOL ran = [[NSRunLoop currentRunLoop] runMode: mode
											beforeDate: [NSDate distantFuture]];
		[loop drain];
		
		// on background threads, it might not have any sources on the runloop immediately,
		//  so we handle that by pausing for a moment so we don't eat all the CPU
		if ( !ran )
			[NSThread sleepForTimeInterval: 0.05];
		
	} while ( !self.complete );
	
	// disable network activity indicator here
	
	[pool drain];
	
	if ( _tmpFilePath == nil )
		return ( NO );
	
	return ( YES );
}

- (void) _performAsynchronousRequest: (NSURLRequest *) request
{
	self.complete = NO;
	self.request = request;
	_asyncTimeouts = 0;
	_thread = [NSThread currentThread];	// remember which thread is blocking on the network I/O
	
	// we'll add to the multiplexer thread when we return to the runloop
	[AQConnectionMultiplexer performSelector: @selector(attachDownloadHelper:)
								  withObject: self
								  afterDelay: 0.0];
	
	// that's it for now
}

- (NSURLRequest *) connection: (NSURLConnection *) connection
			  willSendRequest: (NSURLRequest *) request
			 redirectResponse: (NSURLResponse *) redirectResponse
{
	if ( redirectResponse == nil )
		return ( request );
	
	// there's a redirect in progress -- handle it however you would here, returning
	//  the request you want to be processed at the end
	
	return ( request );
}

- (void) connection: (NSURLConnection *) connection
didReceiveAuthenticationChallenge: (NSURLAuthenticationChallenge *) challenge
{
	// if the authentication didn't work before, it won't work this time
	if ( [challenge previousFailureCount] > 0 )
	{
		[[challenge sender] cancelAuthenticationChallenge: challenge];
		return;
	}
	
	// if we don't have a credential provider, cancel the authentication challenge
	if ( self.authProvider == nil )
	{
		[[challenge sender] cancelAuthenticationChallenge: challenge];
		return;
	}
	
	NSURLCredential * credential = [[NSURLCredential alloc] initWithUser: self.authProvider.username
																password: self.authProvider.password
															 persistence: NSURLCredentialPersistenceNone];
	
	[[challenge sender] useCredential: credential forAuthenticationChallenge: challenge];
	[credential release];
}

- (void) connection: (NSURLConnection *) connection didReceiveResponse: (NSURLResponse *) response
{
	// store the response so the caller can look at it
	self.response = response;
}

- (void) connection: (NSURLConnection *) connection didReceiveData: (NSData *) data
{
	// push the data out to disk immediately
	[_tmpFileHandle writeData: data];
}

- (void) connectionDidFinishLoading: (NSURLConnection *) connection
{
	// we mark completion on the starting thread, to ensure that the runloop on a
	//  synchronous operation will return from its -runMode:beforeDate: method immediately
	[self performSelector: @selector(_markComplete)
				 onThread: _thread
			   withObject: nil
			waitUntilDone: NO];
}

- (void) _markComplete
{
	self.complete = YES;
}

- (void) connection: (NSURLConnection *) connection didFailWithError: (NSError *) error
{
	NSLog( @"*** Error loading URL %@ - %@", [[error userInfo] objectForKey: NSErrorFailingURLStringKey], error );
	self.error = error;
	
	// we have slightly different error handling based on whether we're doing a synchronous or
	//  asynchronous operation
	if ( (self.asyncDelegate != nil) && ([error code] == NSURLErrorTimedOut) )
	{
		// if async, we restart here if a timeout is encountered
		if ( ++_asyncTimeouts < 3 )
		{
			// empty file
			[_tmpFileHandle truncateFileAtOffset: 0];
			
			// cancel existing connection (might as well)
			[self.connection cancel];
			
			// fire off a new connection
			[self start];
			
			// that's it for now
			return;
		}
	}
	
	// operation is complete, albeit failed
	[_tmpFilePath release];
	_tmpFilePath = nil;
	
	[self performSelector: @selector(_markComplete)
				 onThread: _thread
			   withObject: nil
			waitUntilDone: NO];
}

- (NSCachedURLResponse *) connection: (NSURLConnection *) connection
				   willCacheResponse: (NSCachedURLResponse *) cachedResponse
{
	// no caching of responses
	return ( nil );
}

@end
