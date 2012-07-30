/*
 * AQGzipStream.h
 * AQToolkit
 * 
 * Created by Jim Dovey on 20/4/2009.
 * 
 * Copyright (c) 2009 Jim Dovey
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 
 * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * 
 * Neither the name of the project's author nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#import <Foundation/Foundation.h>

@class _AQGzipStreamInternal;

// these values match those from <zlib.h>
enum
{
    AQGzipCompressionLevelDefault   = -1,
    
    AQGzipCompressionLevelNone      =  0,
    
    AQGzipCompressionLevelFastest   =  1,
    // ... levels 2-8 are implied
    AQGzipCompressionLevelBest      =  9
};
typedef NSInteger AQGzipCompressionLevel;

////////////////////////////////////////////////////////////////////////

// all these properties can only be set prior to opening the stream

@protocol AQGzipMemoryStreamOptimisation <NSObject>
@property (nonatomic) NSInteger inputBufferSize;
@property (nonatomic) NSInteger outputBufferSize;
@end

@protocol AQGzipOutputCompressor <NSObject>
@property (nonatomic) AQGzipCompressionLevel compressionLevel;
@end

////////////////////////////////////////////////////////////////////////

// would be nice if these two could have a common ancestor, but sadly they each
//  need to be subclasses of different parents
// My way around this is for each thing to *contain* a common instance, which stores
//  all the common state information, etc.
@interface AQGzipInputStream : NSInputStream <AQGzipMemoryStreamOptimisation, NSStreamDelegate>
{
    NSInputStream *         _compressedDataStream;
    _AQGzipStreamInternal * _internal;
}

// designated initializer
- (id) initWithCompressedStream: (NSInputStream *) stream;
// creates a memory stream from the compressed data
- (id) initWithCompressedData: (NSData *) data;

@end

@interface AQGzipOutputStream : NSOutputStream <AQGzipMemoryStreamOptimisation, AQGzipOutputCompressor, NSStreamDelegate>
{
    NSOutputStream *        _outputStream;
    _AQGzipStreamInternal * _internal;
    AQGzipCompressionLevel  _level;
}

// designated initializer
- (id) initWithDestinationStream: (NSOutputStream *) stream;

@end

////////////////////////////////////////////////////////////////////////
// Gzip FileIO-based streams

// these categories return private subclasses (yay for class-clusters)
//  which use the high-level gzFile APIs to deal with files. This means
//  that the output stream in particular produces an actual gzip *file*,
//  with a header, not just a blob of compressed data.

@interface AQGzipInputStream (GzipFileInput)
+ (id) gzipStreamWithFileAtPath: (NSString *) path;
- (id) initWithGzipFileAtPath: (NSString *) path;
@end

@interface AQGzipOutputStream (GzipFileOutput)
+ (id<AQGzipOutputCompressor>) gzipStreamToFileAtPath: (NSString *) path;
- (id<AQGzipOutputCompressor>) initToGzipFileAtPath: (NSString *) path;
@end

////////////////////////////////////////////////////////////////////////
// Constants

extern NSString * const AQZlibErrorDomain;
