//
//  AQChunkedXMLData.h
//  AQToolkit
//
//  Created by Jim Dovey on 21/02/09.
//  Copyright 2009 Morfunk, LLC. All rights reserved.
//

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
