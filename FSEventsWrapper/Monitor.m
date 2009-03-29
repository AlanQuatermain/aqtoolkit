/*
 *  AQFSEventStream.m
 *  AQToolkit
 *
 *  Created by Jim Dovey on 17/2/2009.
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

#import <sysexits.h>
#import "AQFSEventStream.h"

static BOOL _Run = YES;

static void _Terminate( int sig )
{
	_Run = NO;
}

#pragma mark -

@interface StreamDelegate : NSObject <AQFSEventStreamDelegate>
@end

@implementation StreamDelegate

- (void) foldersUpdated: (NSArray *) paths
{
	fprintf( stdout, "The following folders were updated:\n%s\n", [[paths description] UTF8String] );
}

- (void) eventHistoryDone
{
	fprintf( stdout, "Finished processing historical events\n" );
}

- (void) rootPathChanged: (NSString *) path
{
	fprintf( stdout, "Root path changed: %s\n", [path UTF8String] );
}

- (void) scanSubDirs: (NSString *) path
{
	fprintf( stdout, "Need to scan subdirectories: %s\n", [path UTF8String] );
}

- (void) volumeMounted: (NSString *) path
{
	fprintf( stdout, "Volume mounted: %s\n", [path UTF8String] );
}

- (void) volumeUnmounted: (NSString *) path
{
	fprintf( stdout, "Volume unmounted: %s\n", [path UTF8String] );
}

@end

#pragma mark -

int main( int argc, const char * const argv[] )
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	if ( argc != 2 )
	{
		fprintf( stderr, "Usage: Monitor <folder-name>\n" );
		exit( EX_USAGE );
	}
	
	// get a standardized path (makes it an absolute path with no .. or . components)
	NSString * path = [[NSString stringWithCString: argv[1] encoding: NSUTF8StringEncoding] stringByStandardizingPath];
	
	signal( SIGTERM, _Terminate );
	signal( SIGINT,  _Terminate );
	
	StreamDelegate * delegate = [[StreamDelegate alloc] init];
	AQFSEventStream * stream = [AQFSEventStream startedEventStreamForPaths: [NSSet setWithObject: path]];
	stream.delegate = delegate;
	
	while ( _Run )
	{
		NSAutoreleasePool * loop = [[NSAutoreleasePool alloc] init];
		[[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode beforeDate: [NSDate dateWithTimeIntervalSinceNow: 0.5]];
		[loop drain];
	}
	
	[stream stop];
	[stream invalidate];
	
	[pool drain];
	return ( 0 );
}
