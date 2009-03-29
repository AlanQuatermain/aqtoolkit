/*
 *  AQChunkedXMLData.m
 *  AQToolkit
 *
 *  Created by Jim Dovey on 21/02/2009.
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
