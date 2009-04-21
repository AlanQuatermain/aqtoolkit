/*
 * _AQGzipStreamInternal.h
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

#import "AQGzipStream.h"
#import <zlib.h>
#import <mach/mach_port.h>
#import <mach/mach_init.h>

#import "iPhoneNonatomic.h"

#if TARGET_OS_MAC
# import <libkern/OSAtomic.h>
#endif

@interface _AQGzipStreamInternal : NSObject
{
    z_stream * __strong         _zStream;
    NSError *                   _error;
    NSStreamStatus              _status;
    id __weak                   _delegate;
    Bytef *                     _input;
    Bytef *                     _output;
    NSUInteger                  _writeOffset;
    NSUInteger                  _readOffset;    // offset from _zStream->output at which to begin reading
    CFRunLoopSourceRef __strong _runloopSource;
    mach_port_t                 _port;

    // used to implement atomic access to z_stream members on Macintosh
#if TARGET_OS_MAC
    OSSpinLock                  _lock;
#endif
}

@property (NS_NONATOMIC_IPHONEONLY assign) z_stream * __strong zStream;
@property (NS_NONATOMIC_IPHONEONLY retain) NSError * error;
@property (NS_NONATOMIC_IPHONEONLY readwrite) NSStreamStatus status;
@property (NS_NONATOMIC_IPHONEONLY assign) id __weak delegate;
@property (nonatomic, readonly) Bytef * input;
@property (nonatomic, readonly) Bytef * output;
@property (NS_NONATOMIC_IPHONEONLY assign) NSUInteger writeOffset;
@property (NS_NONATOMIC_IPHONEONLY assign) NSUInteger readOffset;
@property (NS_NONATOMIC_IPHONEONLY readonly) CFRunLoopSourceRef runloopSource;
@property (NS_NONATOMIC_IPHONEONLY readonly) mach_port_t port;

/////////////////////////////////////////////////////////
// z_stream member accessors

@property (NS_NONATOMIC_IPHONEONLY readwrite) Bytef * next_in;
@property (NS_NONATOMIC_IPHONEONLY readwrite) uInt avail_in;
@property (NS_NONATOMIC_IPHONEONLY readwrite) uLong total_in;

@property (NS_NONATOMIC_IPHONEONLY readwrite) Bytef * next_out;
@property (NS_NONATOMIC_IPHONEONLY readwrite) uInt avail_out;
@property (NS_NONATOMIC_IPHONEONLY readwrite) uLong total_out;

@property (NS_NONATOMIC_IPHONEONLY readonly) char * msg;

/////////////////////////////////////////////////////////

- (void) createRunloopSourceForStream: (id) stream;
- (void) postStreamEvent: (NSStreamEvent) event;
- (void) setStatusForStream: (NSStream *) stream;
- (void) setZlibError: (int) error;

/////////////////////////////////////////////////////////

@property (nonatomic, readonly) NSInteger inputRoom;
@property (nonatomic, readonly) void * inputPtr;

@property (nonatomic, readonly) NSInteger outputAvailable;
@property (nonatomic, readonly) const void * outputPtr;

- (NSInteger) writeInputFromBuffer: (const void *) buffer length: (NSInteger) length;
- (NSInteger) readOutputToBuffer: (void *) buffer length: (NSInteger) length;

@end
