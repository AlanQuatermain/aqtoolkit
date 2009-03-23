/*
 *  AQChunkedXMLData.m
 *  AQToolkit
 *
 *  Created by Jim Dovey on 21/02/2009.
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

#import "AQChunkedXMLData.h"

enum
{
	kRegularChunk			= 0,
	kFirstChunk				= 1,
	kFirstChunkRemainder	= 2
	
};

@interface _AQXMLDataChunk : NSObject
{
	@public
	uint8_t bytes[PAGE_SIZE];
	NSUInteger length;
}
+ (_AQXMLDataChunk *) chunkFromStream: (NSInputStream *) stream;
@end

@implementation _AQXMLDataChunk

+ (_AQXMLDataChunk *) chunkFromStream: (NSInputStream *) stream
{
	_AQXMLDataChunk * chunk = [[self alloc] init];
	NSInteger len = [stream read: chunk->bytes maxLength: PAGE_SIZE];
	if ( len < 0 )
	{
		[chunk release];
		return ( nil );
	}
	
	chunk->length = (NSUInteger) len;
	return ( [chunk autorelease] );
}

@end

#pragma mark -

@implementation AQChunkedXMLData

+ (AQChunkedXMLData *) dataWithContentsOfFile: (NSString *) path
{
	NSInputStream * stream = [NSInputStream inputStreamWithFileAtPath: path];
	return ( [self dataFromStream: stream] );
}

+ (AQChunkedXMLData *) dataFromStream: (NSInputStream *) stream
{
	return ( [[[self alloc] initWithStream: stream] autorelease] );
}

- (id) initWithStream: (NSInputStream *) stream
{
	if ( [super init] == nil )
		return ( nil );
	
	_stream = [stream retain];
	_chunk = [[_AQXMLDataChunk chunkFromStream: stream] retain];
	_flags.chunkType = kFirstChunk;
	
	return ( self );
}

- (BOOL) getNextChunk
{
	if ( _flags.chunkType == kFirstChunk )
	{
		_flags.chunkType = kFirstChunkRemainder;
		if ( _chunk->length > 4 )
			return ( YES );
		return ( NO );
	}
	
	[_chunk release];
	_chunk = nil;
	
	_AQXMLDataChunk * newChunk = [_AQXMLDataChunk chunkFromStream: _stream];
	if ( (newChunk == nil) || (newChunk->length == 0) )
		return ( NO );
	
	_chunk = [newChunk retain];
	return ( YES );
}

- (BOOL) isLastChunk
{
	if ( _chunk == nil )
		return ( YES );
	
	if ( _flags.chunkType == kFirstChunk )
	{
		if ( _chunk->length > 4 )
			return ( NO );
	}
	
	return ( [_stream hasBytesAvailable] );
}

- (const void *) bytes
{
	if ( _chunk == nil )
		return ( NULL );
	
	return ( _chunk->bytes );
}

- (NSUInteger) length
{
	if ( _chunk == nil )
		return ( 0 );
	
	if ( _flags.chunkType == kFirstChunk )
		return ( MIN(_chunk->length, 4) );
	
	if ( _flags.chunkType == kFirstChunkRemainder )
	{
		if ( _chunk->length > 4 )
			return ( _chunk->length - 4 );
		else
			return ( 0 );
	}
	
	return ( _chunk->length );
}

@end
