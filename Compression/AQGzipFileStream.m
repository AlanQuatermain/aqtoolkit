/*
 * AQGzipFileStream.m
 * Compression
 * 
 * Created by Jim Dovey on 21/4/2009.
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
#import "AQGzipStream.h"

#import <zlib.h>
#import <mach/mach_port.h>
#import <mach/mach_init.h>

@interface AQGzipFileInputStream : NSInputStream
{
    NSString *          _path;
    gzFile              _file;
    CFRunLoopSourceRef  _rls;
    mach_port_t         _port;
    id __weak           _delegate;
    NSError *           _error;
    NSStreamStatus      _status;
}
@end

@interface AQGzipFileOutputStream : NSOutputStream <AQGzipOutputCompressor>
{
    NSString *              _path;
    gzFile                  _file;
    CFRunLoopSourceRef      _rls;
    mach_port_t             _port;
    id __weak               _delegate;
    NSError *               _error;
    NSStreamStatus          _status;
    AQGzipCompressionLevel  _level;
}
@end

@implementation AQGzipInputStream (GzipFileInput)

+ (id) gzipStreamWithFileAtPath: (NSString *) path
{
    return ( [[[AQGzipFileInputStream alloc] initWithPath: path] autorelease] );
}

- (id) initWithGzipFileAtPath: (NSString *) path
{
    id result = [[AQGzipFileInputStream alloc] initWithPath: path];
    [self release];
    return ( result );
}

@end

@implementation AQGzipOutputStream (GzipFileOutput)

+ (id<AQGzipOutputCompressor>) gzipStreamToFileAtPath: (NSString *) path
{
    return ( [[[AQGzipFileOutputStream alloc] initWithPath: path] autorelease] );
}

- (id<AQGzipOutputCompressor>) initToGzipFileAtPath: (NSString *) path
{
    id result = [[AQGzipFileOutputStream alloc] initWithPath: path];
    [self release];
    return ( result );
}

@end

#pragma mark -

NSError * CreateGZFileError( gzFile file )
{
    int err = 0;
    const char * msg = gzerror( file, &err );
    
    if ( err == Z_ERRNO )
        return ( [NSError errorWithDomain: NSPOSIXErrorDomain code: errno userInfo: nil] );
    
    NSString * desc = [[NSString alloc] initWithUTF8String: msg];
    NSDictionary * userInfo = [[NSDictionary alloc] initWithObjectsAndKeys: desc, NSLocalizedDescriptionKey, nil];
    
    NSError * result = [NSError errorWithDomain: AQZlibErrorDomain
                                           code: err
                                       userInfo: userInfo];
    
    [desc release];
    [userInfo release];
    
    return ( result );
}

struct _stream_event_msg
{
    mach_msg_header_t   header;
    mach_msg_body_t     body;
    NSStreamEvent       event;
};

@interface NSObject (AQGzipStreamSourceHandler)
- (mach_port_t) _runloopPort;
- (void) _postEventToDelegate: (NSStreamEvent) event;
@end

static mach_port_t __AQGzipGetPort( void * info )
{
    return ( [(id)info _runloopPort] );
}

static void * __AQGzipPerform( void * msg, CFIndex size, CFAllocatorRef allocator, void * info )
{
    id obj = (id) info;
    struct _stream_event_msg *pMsg = (struct _stream_event_msg *) msg;
    
    [obj _postEventToDelegate: pMsg->event];
    
    return ( NULL );
}

static CFRunLoopSourceRef RunloopSourceForStream( NSStream * stream, mach_port_t * port )
{
    // allocate with receive right
    kern_return_t kr = mach_port_allocate( mach_task_self(), MACH_PORT_RIGHT_RECEIVE, port );
    if ( kr != KERN_SUCCESS )
        return ( NULL );
    
    // insert a make-send right so others can post to us
    kr = mach_port_insert_right( mach_task_self(), *port, *port, MACH_MSG_TYPE_MAKE_SEND );
    if ( kr != KERN_SUCCESS )
    {
        (void) mach_port_destroy( mach_task_self(), *port );
        return ( NULL );
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
    
    return ( CFRunLoopSourceCreate(kCFAllocatorDefault, 0,  (CFRunLoopSourceContext *)&ctx) );
}

#pragma mark -

@implementation AQGzipFileInputStream

- (id) initWithPath: (NSString *) path
{
    if ( [super init] == nil )
        return ( nil );
    
    _path = [path copy];
    
    return ( self );
}

- (void) dealloc
{
    [self close];
    
    if ( _port != MACH_PORT_NULL )
        (void) mach_port_deallocate( mach_task_self(), _port );
    
    if ( _rls != NULL )
    {
        CFRunLoopSourceInvalidate( _rls );
        CFRelease( _rls );
    }
    
    [_path release];
    [_error release];
    
    [super dealloc];
}

- (void) finalize
{
    [self close];
    
    if ( _port != MACH_PORT_NULL )
        (void) mach_port_deallocate( mach_task_self(), _port );
    
    if ( _file != NULL )
        gzclose( _file );
    
    [super finalize];
}

- (id) delegate
{
    return ( _delegate );
}

- (void) setDelegate: (id) delegate
{
    _delegate = delegate;
}

- (NSError *) streamError
{
    return ( _error );
}

- (NSStreamStatus) streamStatus
{
    return ( _status );
}

- (void) scheduleInRunLoop: (NSRunLoop *) aRunLoop forMode: (NSString *) mode
{
    if ( _rls == NULL )
        _rls = (CFRunLoopSourceRef) CFMakeCollectable( RunloopSourceForStream(self, &_port) );
    CFRunLoopAddSource( [aRunLoop getCFRunLoop], _rls, (CFStringRef)mode );
}

- (void) removeFromRunLoop: (NSRunLoop *) aRunLoop forMode: (NSString *) mode
{
    if ( _rls != NULL )
        CFRunLoopRemoveSource( [aRunLoop getCFRunLoop], _rls, (CFStringRef)mode );
}

- (void) postStreamEvent: (NSStreamEvent) event
{
    if ( _rls == NULL )
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
        _error = [[NSError errorWithDomain: NSMachErrorDomain code: kr userInfo: nil] retain];
        _status = NSStreamStatusError;
    }
}

- (void) open
{
    if ( _status != NSStreamStatusNotOpen )
        return;
    
    _file = gzopen( [_path fileSystemRepresentation], "r" );
    if ( _file == NULL )
    {
        _status = NSStreamStatusError;
        _error = [[NSError errorWithDomain: NSPOSIXErrorDomain code: errno userInfo: nil] retain];
        [self postStreamEvent: NSStreamEventErrorOccurred];
        return;
    }
    
    _status = NSStreamStatusOpen;
    [self postStreamEvent: NSStreamEventOpenCompleted];
    
    if ( gzeof(_file) == 0 )
        [self postStreamEvent: NSStreamEventHasBytesAvailable];
}

- (void) close
{
    if ( _file == NULL )
        return;
    
    gzclose( _file );
    _status = NSStreamStatusClosed;
}

- (mach_port_t) _runloopPort
{
    return ( _port );
}

- (void) _postEventToDelegate: (NSStreamEvent) event
{
    [_delegate stream: self handleEvent: event];
}

- (NSInteger) read: (uint8_t *) buffer maxLength: (NSUInteger) len
{
    if ( _status != NSStreamStatusOpen )
        return ( 0 );
    
    _status = NSStreamStatusReading;
    int numRead = gzread( _file, buffer, len );
    _status = NSStreamStatusOpen;
    
    if ( numRead == -1 )
    {
        _error = [CreateGZFileError(_file) retain];
        _status = NSStreamStatusError;
        [self postStreamEvent: NSStreamEventErrorOccurred];
        return ( 0 );
    }
    else if ( (numRead == 0) || (gzeof(_file) == 1) )
    {
        _status = NSStreamStatusAtEnd;
        [self postStreamEvent: NSStreamEventEndEncountered];
    }
    
    return ( (NSInteger) numRead );
}

- (BOOL) getBuffer: (uint8_t **) buffer length: (NSUInteger *) len
{
    return ( NO );
}

- (BOOL) hasBytesAvailable
{
    return ( gzeof(_file) == 0 );
}

@end

#pragma mark -

@implementation AQGzipFileOutputStream

@synthesize compressionLevel=_level;

- (id) initWithPath: (NSString *) path
{
    if ( [super init] == nil )
        return ( nil );
    
    _path = [path copy];
    _level = AQGzipCompressionLevelDefault;
    
    return ( self );
}

- (void) dealloc
{
    [self close];
    
    if ( _port != MACH_PORT_NULL )
        (void) mach_port_deallocate( mach_task_self(), _port );
    
    if ( _rls != NULL )
    {
        CFRunLoopSourceInvalidate( _rls );
        CFRelease( _rls );
    }
    
    [_path release];
    [_error release];
    
    [super dealloc];
}

- (void) finalize
{
    [self close];
    
    if ( _port != MACH_PORT_NULL )
        (void) mach_port_deallocate( mach_task_self(), _port );
    
    if ( _file != NULL )
        gzclose( _file );
    
    [super finalize];
}

- (id) delegate
{
    return ( _delegate );
}

- (void) setDelegate: (id) delegate
{
    _delegate = delegate;
}

- (NSError *) streamError
{
    return ( _error );
}

- (NSStreamStatus) streamStatus
{
    return ( _status );
}

- (void) scheduleInRunLoop: (NSRunLoop *) aRunLoop forMode: (NSString *) mode
{
    if ( _rls == NULL )
        _rls = (CFRunLoopSourceRef) CFMakeCollectable( RunloopSourceForStream(self, &_port) );
    CFRunLoopAddSource( [aRunLoop getCFRunLoop], _rls, (CFStringRef)mode );
}

- (void) removeFromRunLoop: (NSRunLoop *) aRunLoop forMode: (NSString *) mode
{
    if ( _rls != NULL )
        CFRunLoopRemoveSource( [aRunLoop getCFRunLoop], _rls, (CFStringRef)mode );
}

- (void) postStreamEvent: (NSStreamEvent) event
{
    if ( _rls == NULL )
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
        _error = [[NSError errorWithDomain: NSMachErrorDomain code: kr userInfo: nil] retain];
        _status = NSStreamStatusError;
    }
}

- (void) open
{
    if ( _status != NSStreamStatusNotOpen )
        return;
    
    NSString * modeStr = @"w";
    if ( _level != AQGzipCompressionLevelDefault )
        modeStr = [[NSString alloc] initWithFormat: @"w%ld", _level];
    
    _file = gzopen( [_path fileSystemRepresentation], [modeStr UTF8String] );
    [modeStr release];
    
    if ( _file == NULL )
    {
        _status = NSStreamStatusError;
        _error = [[NSError errorWithDomain: NSPOSIXErrorDomain code: errno userInfo: nil] retain];
        [self postStreamEvent: NSStreamEventErrorOccurred];
        return;
    }
    
    _status = NSStreamStatusOpen;
    [self postStreamEvent: NSStreamEventOpenCompleted];
    [self postStreamEvent: NSStreamEventHasSpaceAvailable];
}

- (void) close
{
    if ( _file == NULL )
        return;
    
    gzclose( _file );
    _status = NSStreamStatusClosed;
}

- (mach_port_t) _runloopPort
{
    return ( _port );
}

- (void) _postEventToDelegate: (NSStreamEvent) event
{
    [_delegate stream: self handleEvent: event];
}

- (NSInteger) write: (uint8_t const *) buffer maxLength: (NSUInteger) len
{
    if ( _status != NSStreamStatusOpen )
        return ( 0 );
    
    _status = NSStreamStatusWriting;
    int numWritten = gzwrite( _file, buffer, len );
    _status = NSStreamStatusOpen;
    
    if ( numWritten == 0 )
    {
        _error = [CreateGZFileError(_file) retain];
        _status = NSStreamStatusError;
        [self postStreamEvent: NSStreamEventErrorOccurred];
    }
    else if ( [self hasSpaceAvailable] )
    {
        [self postStreamEvent: NSStreamEventHasSpaceAvailable];
    }
    
    return ( (NSInteger) numWritten );
}

- (BOOL) hasSpaceAvailable
{
    return ( YES );
}

@end
