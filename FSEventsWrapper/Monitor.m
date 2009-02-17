/*
 *  AQFSEventStream.m
 *  AQToolkit
 *
 *  Created by Jim Dovey on 17/2/2009.
 *  Copyright (c) 2009 Jim Dovey. Some Rights Reserved.
 *
 *  This work is licensed under a Creative Commons
 *  Attribution License. You are free to use, modify,
 *  and redistribute this work, but may only distribute
 *  the resulting work under the same, similar or a
 *  compatible license. In addition, you must include
 *  the following disclaimer:
 *
 *    Portions Copyright (c) 2009 Jim Dovey
 *
 *  For license details, see:
 *    http://creativecommons.org/licenses/by-sa/3.0/
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
