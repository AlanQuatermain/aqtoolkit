/*
 *  AQChunkedXMLData.h
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
