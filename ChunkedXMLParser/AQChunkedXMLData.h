/*
 *  AQChunkedXMLData.h
 *  AQToolkit
 *
 *  Created by Jim Dovey on 21/02/2009.
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

#import <Cocoa/Cocoa.h>

@class _AQXMLDataChunk;

@interface AQChunkedXMLData : NSData
{
	NSInputStream *		_stream;
	_AQXMLDataChunk *	_chunk;
	struct
	{
		unsigned int	chunkType:2;
		unsigned int	__RESERVED:30;
	} _flags;
}

+ (AQChunkedXMLData *) dataWithContentsOfFile: (NSString *) path;
+ (AQChunkedXMLData *) dataFromStream: (NSInputStream *) stream;

// this will load up the first chunk ready for use
- (id) initWithStream: (NSInputStream *) stream;

// this is designed to work with xmlCreatePushParserContext()
// as such, the first chunk is 4 bytes, the next is pagesize-4, then
//  subsequent chunks are page-sized (usually 4096 bytes)

// returns YES if another chunk was available, NO if we reached the end of the data/stream
- (BOOL) getNextChunk;
- (BOOL) isLastChunk;

// these two functions both return details of the current chunk. You've only reached
//  the end of the whole data block when -getNextChunk returns NO and/or -length returns 0
- (const void *) bytes;
- (NSUInteger) length;

@end
