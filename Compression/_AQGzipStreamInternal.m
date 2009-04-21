/*
 * _AQGzipStreamInternal.m
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

#import "_AQGzipStreamInternal.h"
#import <libkern/OSAtomic.h>

// this file implements the common parts of the gzip stream implementation
// i.e. the _AQGzipStreamInternal class

#if TARGET_OS_MAC
# define ATOMIC_LOCK    OSSpinLockLock(&_lock)
# define ATOMIC_UNLOCK  OSSpinLockUnlock(&_lock)
# define ATOMIC_ZSTREAM_GET(val)                        \
    OSSpinLockLock(&_lock);                             \
    __typeof__(_zStream->val) result = _zStream->val;   \
    OSSpinLockUnlock(&_lock);                           \
    return ( result )
# define ATOMIC_ZSTREAM_SET(val, nval)                  \
    OSSpinLockLock(&_lock);                             \
    _zStream->val = nval;                               \
    OSSpinLockUnlock(&_lock)
#else
# define ATOMIC_LOCK
# define ATOMIC_UNLOCK
# define ATOMIC_ZSTREAM_GET(val) return ( _zStream->val )
# define ATOMIC_ZSTREAM_SET(val, nval) _zStream->val = nval
#endif

NSString * const AQZlibErrorDomain = @"AQZlibErrorDomain";

NSError * CreateZlibError( z_stream *pZ, int err )
{
    NSString * desc = [[NSString alloc] initWithUTF8String: pZ->msg];
    NSDictionary * userInfo = [[NSDictionary alloc] initWithObjectsAndKeys: desc, NSLocalizedDescriptionKey, nil];
    
    NSError * result = [NSError errorWithDomain: AQZlibErrorDomain
                                           code: err
                                       userInfo: userInfo];
    
    [desc release];
    [userInfo release];
    
    return ( result );
}

#pragma mark -

struct _stream_event_msg
{
    mach_msg_header_t   header;
    mach_msg_body_t     body;
    NSStreamEvent       event;
};

@interface NSObject (AQGzipStreamSourceHandler)
- (_AQGzipStreamInternal *) _internal;
- (void) _postEventToDelegate: (NSStreamEvent) event;
@end

static mach_port_t __AQGzipGetPort( void * info )
{
    _AQGzipStreamInternal * obj = [(id)info _internal];
    return ( obj.port );
}

static void * __AQGzipPerform( void * msg, CFIndex size, CFAllocatorRef allocator, void * info )
{
    id obj = (id) info;
    struct _stream_event_msg *pMsg = (struct _stream_event_msg *) msg;
    
    [obj _postEventToDelegate: pMsg->event];
    
    return ( NULL );
}

#pragma mark -

@implementation _AQGzipStreamInternal

@synthesize zStream=_zStream;
@synthesize error=_error;
@synthesize status=_status;
@synthesize delegate=_delegate;
@synthesize input=_input;
@synthesize output=_output;
@synthesize writeOffset=_writeOffset;
@synthesize readOffset=_readOffset;
@synthesize runloopSource=_runloopSource;
@synthesize port=_port;

- (id) init
{
    if ( [super init] == nil )
        return ( nil );
    
#if TARGET_OS_IPHONE
    _zStream = NSZoneMalloc( [self zone], sizeof(z_stream) );
    _input   = NSZoneMalloc( [self zone], 1024 );
    _output  = NSZoneMalloc( [self zone], 1024 );
#else
    _zStream = NSAllocateCollectable( sizeof(z_stream), 0 );
    _input   = NSAllocateCollectable( 1024, 0 );
    _output  = NSAllocateCollectable( 1024, 0 );
#endif
    
    _zStream->next_in = _input;
    _zStream->avail_in = 0;
    _zStream->total_in = 0;
    _zStream->next_out = _output;
    _zStream->avail_out = 1024;
    _zStream->total_out = 0;
    _zStream->zalloc = NULL;
    _zStream->zfree = NULL;
    
    return ( self );
}

- (void) dealloc
{
    if ( _runloopSource != NULL )
    {
        CFRunLoopSourceInvalidate( _runloopSource );
        CFRelease( _runloopSource );
    }
    
    if ( _port != MACH_PORT_NULL )
        (void) mach_port_deallocate( mach_task_self(), _port );
    
    NSZoneFree( [self zone], _zStream );
    NSZoneFree( [self zone], _input   );
    NSZoneFree( [self zone], _output  );
    
    [_error release];
    [super dealloc];
}

- (void) finalize
{
    if ( _port != MACH_PORT_NULL )
        (void) mach_port_deallocate( mach_task_self(), _port );
    [super finalize];
}

- (void) createRunloopSourceForStream: (id) stream
{
    // allocate with receive right
    kern_return_t kr = mach_port_allocate( mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &_port );
    if ( kr != KERN_SUCCESS )
        return;
    
    // insert a make-send right so others can post to us
    kr = mach_port_insert_right( mach_task_self(), _port, _port, MACH_MSG_TYPE_MAKE_SEND );
    if ( kr != KERN_SUCCESS )
    {
        (void) mach_port_destroy( mach_task_self(), _port );
        return;
    }
    
    CFRunLoopSourceContext1 ctx = {
        1,                      // version
        stream,                 // info
        CFRetain,               // retain
        CFRelease,              // release
        CFCopyDescription,      // copyDescription
        CFEqual,                // equal
        CFHash,                 // hash
        __AQGzipGetPort,        // getPort
        __AQGzipPerform,        // perform
    };
    
    _runloopSource = (CFRunLoopSourceRef) CFMakeCollectable( CFRunLoopSourceCreate(kCFAllocatorDefault, 0,  (CFRunLoopSourceContext *)&ctx) );
}

- (void) postStreamEvent: (NSStreamEvent) event
{
    if ( _runloopSource == NULL )
        return;
    
    struct _stream_event_msg msg;
    msg.header.msgh_bits = MACH_MSGH_BITS(MACH_MSG_TYPE_COPY_SEND, 0);
    msg.header.msgh_id = 0;
    msg.header.msgh_size = sizeof(struct _stream_event_msg);
    msg.header.msgh_remote_port = _port;
    msg.header.msgh_local_port = MACH_PORT_NULL;
    msg.header.msgh_reserved = 0;
    msg.body.msgh_descriptor_count = 0;
    msg.event = event;
    
    // it's a fire-and-forget message, no reply
    kern_return_t kr = mach_msg( (mach_msg_header_t *) &msg, MACH_SEND_MSG, msg.header.msgh_size,
                                 0, MACH_PORT_NULL, 0, MACH_PORT_NULL );
    if ( kr != KERN_SUCCESS )
    {
        self.error = [NSError errorWithDomain: NSMachErrorDomain code: kr userInfo: nil];
        self.status = NSStreamStatusError;
    }
}

- (void) setZlibError: (int) err
{
    self.error = CreateZlibError( _zStream, err );
    self.status = NSStreamStatusError;
    [self postStreamEvent: NSStreamEventErrorOccurred];
}

- (void) setStatusForStream: (NSStream *) stream
{
    if ( _zStream->total_out > 0 )
    {
        // data available, don't set any weird status
        self.status = NSStreamStatusOpen;
        return;
    }
    
    if ( [stream streamStatus] == NSStreamStatusAtEnd )
    {
        self.status = NSStreamStatusAtEnd;
        [self postStreamEvent: NSStreamEventEndEncountered];
    }
}

#pragma mark z_stream data accessors

- (Bytef *) next_in
{
    ATOMIC_ZSTREAM_GET(next_in);
}

- (void) setNext_in: (Bytef *) value
{
    ATOMIC_ZSTREAM_SET(next_in, value);
}

- (uInt) avail_in
{
    ATOMIC_ZSTREAM_GET(avail_in);
}

- (void) setAvail_in: (uInt) value
{
    ATOMIC_ZSTREAM_SET(avail_in, value);
}

- (uLong) total_in
{
    ATOMIC_ZSTREAM_GET(total_in);
}

- (void) setTotal_in: (uLong) value
{
    ATOMIC_ZSTREAM_SET(total_in, value);
}

- (Bytef *) next_out
{
    ATOMIC_ZSTREAM_GET(next_out);
}

- (void) setNext_out: (Bytef *) value
{
    ATOMIC_ZSTREAM_SET(next_out, value);
}

- (uInt) avail_out
{
    ATOMIC_ZSTREAM_GET(avail_out);
}

- (void) setAvail_out: (uInt) value
{
    ATOMIC_ZSTREAM_SET(avail_out, value);
}

- (uLong) total_out
{
    ATOMIC_ZSTREAM_GET(total_out);
}

- (void) setTotal_out: (uLong) value
{
    ATOMIC_ZSTREAM_SET(total_out, value);
}

- (char *) msg
{
    ATOMIC_ZSTREAM_GET(msg);
}

#pragma mark Read/Write Helpers

- (NSInteger) inputRoom
{
    return ( 1024 - _writeOffset );
}

- (void *) inputPtr
{
    return ( _input + _writeOffset );
}

- (NSInteger) outputAvailable
{
    return ( _zStream->total_out - _readOffset );
}

- (const void *) outputPtr
{
    return ( _output + _readOffset );
}

- (NSInteger) writeInputFromBuffer: (const void *) buffer length: (NSInteger) length
{
    ATOMIC_LOCK;
    
    NSInteger amountToCopy = MIN(self.inputRoom, length);
    memcpy( self.inputPtr, buffer, amountToCopy );
    _writeOffset += amountToCopy;
    
    ATOMIC_UNLOCK;
    
    return ( amountToCopy );
}

- (NSInteger) readOutputToBuffer: (void *) buffer length: (NSInteger) length
{
    ATOMIC_LOCK;
    
    NSInteger amountToCopy = MIN(self.outputAvailable, length);
    memcpy( buffer, self.outputPtr, amountToCopy );
    _readOffset += amountToCopy;
    
    if ( _readOffset == _zStream->total_out )
    {
        // reset output buffer
        _zStream->next_out = _output;
        _zStream->avail_out = 1024;
        _zStream->total_out = 0;
        _readOffset = 0;
    }
    
    ATOMIC_UNLOCK;
    
    return ( amountToCopy );
}

@end
