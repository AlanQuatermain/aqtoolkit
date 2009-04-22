/*
 * AQGzipOutputStream.m
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
#import "_AQGzipStreamInternal.h"

@implementation AQGzipOutputStream

@synthesize compressionLevel=_level;

- (id) initWithDestinationStream: (NSOutputStream *) destinationStream
{
    if ( [super init] == nil )
        return ( nil );
    
    _internal = [[_AQGzipStreamInternal alloc] init];
    
    _outputStream = [destinationStream retain];
    _internal.status = NSStreamStatusNotOpen;
    _level = AQGzipCompressionLevelDefault;
    
    [_outputStream setDelegate: self];
    
    return ( self );
}

- (void) dealloc
{
    [self close];
    [_outputStream release];
    [_internal release];
    [super dealloc];
}

- (void) finalize
{
    [self close];
    [super finalize];
}

- (id) delegate
{
    return ( _internal.delegate );
}

- (void) setDelegate: (id) delegate
{
    _internal.delegate = delegate;
}

- (NSError *) streamError
{
    return ( _internal.error );
}

- (NSStreamStatus) streamStatus
{
    return ( _internal.status );
}

- (void) setCompressionLevel: (AQGzipCompressionLevel) newLevel
{
    if ( _internal.status != NSStreamStatusNotOpen )
        return;
    
    _level = newLevel;
}

- (NSInteger) inputBufferSize
{
    return ( _internal.inputSize );
}

- (void) setInputBufferSize: (NSInteger) value
{
    if ( _internal.status != NSStreamStatusNotOpen )
        return;
    
    _internal.inputSize = value;
}

- (NSInteger) outputBufferSize
{
    return ( _internal.outputSize );
}

- (void) setOutputBufferSize: (NSInteger) value
{
    if ( _internal.status != NSStreamStatusNotOpen )
        return;
    
    _internal.outputSize = value;
}

- (void) open
{
    if ( _internal.status != NSStreamStatusNotOpen )
        return;
    
    if ( [_outputStream streamStatus] == NSStreamStatusNotOpen )
        [_outputStream open];
    
    // we're not open until we've called deflateInit2()
    _internal.status = NSStreamStatusOpening;
}

- (void) close
{
    if ( (_internal.status == NSStreamStatusNotOpen) ||
         (_internal.status >= NSStreamStatusClosed) )
        return;
    
    int err = deflateEnd( _internal.zStream );
    if ( err < Z_OK )
        [_internal setZlibError: err];
    
    [_outputStream close];
    _internal.status = (err < Z_OK ? NSStreamStatusError : NSStreamStatusClosed);
}

- (_AQGzipStreamInternal *) _internal
{
    return ( _internal );
}

- (void) _postEventToDelegate: (NSStreamEvent) event
{
    [_internal.delegate stream: self handleEvent: event];
}

- (int) _handlePendingInput
{
    // try to compress some more input
    int err = deflate( _internal.zStream, Z_SYNC_FLUSH );
    if ( err < Z_OK )
    {
        [_outputStream close];
        [_internal setZlibError: err];
    }
    else if ( _internal.avail_in == 0 )
    {
        _internal.next_in = _internal.input;
        _internal.avail_in = 0;
        _internal.writeOffset = 0;
    }
    
    return ( err );
}

- (void) stream: (NSOutputStream *) stream handleEvent: (NSStreamEvent) event
{
    switch ( event )
    {
        case NSStreamEventErrorOccurred:
        {
            _internal.error = [stream streamError];
            _internal.status = NSStreamStatusError;
            [stream close];
            [_internal postStreamEvent: NSStreamEventErrorOccurred];
            break;
        }
            
        case NSStreamEventEndEncountered:
        {
            if ( _internal.status == NSStreamStatusAtEnd )
                break;
            
            _internal.status = NSStreamStatusAtEnd;
            [_internal postStreamEvent: NSStreamEventEndEncountered];
            break;
        }
            
        case NSStreamEventHasSpaceAvailable:
        {
            BOOL sentData = NO;
            if ( (_internal.outputAvailable == 0) && (_internal.avail_in > 0) )
            {
                if ( [self _handlePendingInput] < Z_OK )
                    break;
            }
            
            while ( _internal.outputAvailable > 0 )
            {
                // there's something to send
                (void) [_internal readOutputToStream: _outputStream];
                sentData = YES;
                
                if ( ([_outputStream hasSpaceAvailable] == NO) ||
                     (_internal.avail_in == 0) )
                    break;
                
                if ( [self _handlePendingInput] < Z_OK )
                    return;
            }
            
            if ( (_internal.inputRoom > 0) && (!sentData) )
                [_internal postStreamEvent: NSStreamEventHasSpaceAvailable];
            break;
        }
            
        default:
            break;
    }
}

- (void) scheduleInRunLoop: (NSRunLoop *) aRunLoop forMode: (NSString *) mode
{
    // our own callbacks are fed by those of the source stream
    [_outputStream scheduleInRunLoop: aRunLoop forMode: mode];
    
    if ( _internal.runloopSource == NULL )
        [_internal createRunloopSourceForStream: self];
    CFRunLoopAddSource( [aRunLoop getCFRunLoop], _internal.runloopSource, (CFStringRef)mode );
}

- (void) removeFromRunLoop: (NSRunLoop *) aRunLoop forMode: (NSString *) mode
{
    [_outputStream removeFromRunLoop: aRunLoop forMode: mode];
    if ( _internal.runloopSource != NULL )
        CFRunLoopRemoveSource( [aRunLoop getCFRunLoop], _internal.runloopSource, (CFStringRef)mode );
}

- (NSInteger) write: (const uint8_t *) buffer maxLength: (NSUInteger) length
{
    if ( [self hasSpaceAvailable] == NO )
        return ( 0 );
    
    if ( _internal.status == NSStreamStatusOpening )
    {
        int err = deflateInit2( _internal.zStream, _level, Z_DEFLATED, 
                                (15+16), 8, Z_DEFAULT_STRATEGY );
        if ( err != Z_OK )
        {
            [_outputStream close];
            [_internal setZlibError: err];
            return ( 0 );
        }
        
        _internal.status = NSStreamStatusOpen;
    }
    
    if ( _internal.status != NSStreamStatusOpen )
        return ( 0 );
    
    _internal.status = NSStreamStatusWriting;
    NSInteger copied = [_internal writeInputFromBuffer: buffer length: length];
    _internal.status = NSStreamStatusOpen;
    
    if ( [_outputStream hasSpaceAvailable] )
        [self stream: _outputStream handleEvent: NSStreamEventHasSpaceAvailable];
    
    return ( copied );
}

- (BOOL) hasSpaceAvailable
{
    return ( _internal.inputRoom > 0 );
}

- (id) propertyForKey: (NSString *) key
{
    return ( [_outputStream propertyForKey: key] );
}

- (void) setProperty: (id) property forKey: (NSString *) key
{
    [_outputStream setProperty: property forKey: key];
}

@end
