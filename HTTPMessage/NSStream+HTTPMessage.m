//
//  NSStream+HTTPMessage.m
//  Kobov3
//
//  Created by Jim Dovey on 10-04-08.
//  Copyright 2010 Kobo Inc. All rights reserved.
//

#import "NSStream+HTTPMessage.h"

#if TARGET_OS_IPHONE
#import <CFNetwork/CFNetwork.h>
#else
#import <CoreServices/CoreServices.h>
#endif

@implementation NSStream (HTTPMessage)

- (HTTPMessage *) finalRequestMessage
{
	CFHTTPMessageRef cf = NULL;
	if ( [self isKindOfClass: [NSInputStream class]] )
		cf = (CFHTTPMessageRef)CFReadStreamCopyProperty( (CFReadStreamRef)self, kCFStreamPropertyHTTPFinalRequest );
	else
		cf = (CFHTTPMessageRef)CFWriteStreamCopyProperty( (CFWriteStreamRef)self, kCFStreamPropertyHTTPFinalRequest );
	if ( cf == NULL )
		return ( nil );
	
	HTTPMessage * result = [[HTTPMessage alloc] initWithCFHTTPMessageRef: cf];
	CFRelease( cf );
	
	return ( [result autorelease] );
}

- (HTTPMessage *) responseMessageHeader
{
	CFHTTPMessageRef cf = NULL;
	if ( [self isKindOfClass: [NSInputStream class]] )
		cf = (CFHTTPMessageRef)CFReadStreamCopyProperty( (CFReadStreamRef)self, kCFStreamPropertyHTTPResponseHeader );
	else
		cf = (CFHTTPMessageRef)CFWriteStreamCopyProperty( (CFWriteStreamRef)self, kCFStreamPropertyHTTPResponseHeader );
	if ( cf == NULL )
		return ( nil );
	
	HTTPMessage * result = [[HTTPMessage alloc] initWithCFHTTPMessageRef: cf];
	CFRelease( cf );
	
	return ( [result autorelease] );
}

- (NSURL *) finalURL
{
	return ( (NSURL *)[self propertyForKey: (NSString *)kCFStreamPropertyHTTPFinalURL] );
}

@end
