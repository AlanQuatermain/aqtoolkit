//
//  AQGzipInputStream.m
//  AQToolkit
//
//  Created by Jim Dovey on 20/04/09.
//  Copyright 2009 Morfunk, LLC. All rights reserved.
//

#import "AQGzipStream.h"
#import "_AQGzipStreamInternal.h"

@implementation AQGzipInputStream

- (id) initWithCompressedStream: (NSInputStream *) compressedStream
{
    if ( [super init] == nil )
        return ( nil );
    
    _internal = [[_AQGzipStreamInternal alloc] init];
    _compressedDataStream = [compressedStream retain];
    _internal.status = NSStreamStatusNotOpen;
    
    [_compressedDataStream setDelegate: self];
    
    return ( self );
}

- (id) initWithCompressedData: (NSData *) compressedData
{
    NSInputStream * stream = [[NSInputStream alloc] initWithData: compressedData];
    id result = [self initWithCompressedStream: stream];
    [stream release];
    return ( result );
}

- (void) dealloc
{
    [self close];
    
    [_compressedDataStream release];
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
    
    if ( [_compressedDataStream streamStatus] == NSStreamStatusNotOpen )
        [_compressedDataStream open];
    
    _internal.status = NSStreamStatusOpening;
}

- (void) close
{
    if ( _internal.status == NSStreamStatusNotOpen )
        return;
    
    int err = inflateEnd( _internal.zStream );
    if ( err < Z_OK )
        [_internal setZlibError: err];
    
    [_compressedDataStream close];
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

- (void) stream: (NSStream *) stream handleEvent: (NSStreamEvent) event
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
            
            if ( (_internal.total_out == 0) && (_internal.avail_in == 0) )
            {
                _internal.status = NSStreamStatusAtEnd;
                [_internal postStreamEvent: NSStreamEventEndEncountered];
            }
            
            break;
        }
            
        case NSStreamEventHasBytesAvailable:
        {
            // make sure we don't overwrite the bounds of the input buffer
            if ( _internal.inputRoom == 0 )
                break;
            
            NSInteger numRead = [_internal writeInputFromStream: _compressedDataStream];
            if ( numRead > 0 )
            {
                int status = Z_OK;
                if ( _internal.status == NSStreamStatusOpening )
                {
                    status = inflateInit2( _internal.zStream, (15+32) );
                    if ( status != Z_OK )
                    {
                        [stream close];
                        [_internal setZlibError: status];
                        break;
                    }
                    
                    _internal.status = NSStreamStatusOpen;
                    [_internal postStreamEvent: NSStreamEventOpenCompleted];
                }
                
                // attempt to decompress some data
                status = inflate( _internal.zStream, Z_SYNC_FLUSH );
                if ( status < Z_OK )
                {
                    [stream close];
                    [_internal setZlibError: status];
                    break;
                }
                
                // if it used all the input data we'll reset the input buffer
                if ( _internal.avail_in == 0 )
                {
                    _internal.next_in = _internal.input;
                    _internal.writeOffset = 0;
                }
                
                // if it put data into the output we post the appropriate event
                if ( _internal.outputAvailable > 0 )
                    [_internal postStreamEvent: NSStreamEventHasBytesAvailable];
            }
            
            break;
        }
            
        default:
            break;
    }
}

- (void) scheduleInRunLoop: (NSRunLoop *) aRunLoop forMode: (NSString *) mode
{
    // our own callbacks are fed by those of the source stream
    [_compressedDataStream scheduleInRunLoop: aRunLoop forMode: mode];
    
    if ( _internal.runloopSource == NULL )
        [_internal createRunloopSourceForStream: self];
    CFRunLoopAddSource( [aRunLoop getCFRunLoop], _internal.runloopSource, (CFStringRef)mode );
}

- (void) removeFromRunLoop: (NSRunLoop *) aRunLoop forMode: (NSString *) mode
{
    [_compressedDataStream removeFromRunLoop: aRunLoop forMode: mode];
    if ( _internal.runloopSource != NULL )
        CFRunLoopRemoveSource( [aRunLoop getCFRunLoop], _internal.runloopSource, (CFStringRef)mode );
}

- (void) _handlePendingInput
{
    if ( _internal.avail_in > 0 )
    {
        int err = inflate( _internal.zStream, Z_SYNC_FLUSH );
        if ( err < Z_OK )
        {
            [_internal setZlibError: err];
            [_compressedDataStream close];
            return;
        }
        
        if ( _internal.avail_in == 0 )
        {
            _internal.next_in = _internal.input;
            _internal.writeOffset = 0;
        }
    }
}

- (NSInteger) read: (uint8_t *) buffer maxLength: (NSUInteger) len
{
    if ( _internal.status != NSStreamStatusOpen )
        return ( 0 );
    
    NSUInteger ready = _internal.outputAvailable;
    if ( ready == 0 )
        return ( 0 );
    
    NSInteger totalRead = 0;
    
    _internal.status = NSStreamStatusReading;
    while ( (ready > 0) && (ready <= len) )
    {
        // a simple case -- we read everything out of the buffer
        [_internal readOutputToBuffer: buffer + totalRead length: len];
        
        // see if we can get more data decompressed now that we've emptied the output buffer
        [self _handlePendingInput];
        
        // check to see if all data has been decompressed
        [_internal setStatusForStream: _compressedDataStream];
        
        totalRead += ready;
        len -= ready;
        ready = _internal.outputAvailable;
    }
    
    if ( ready == 0 )
    {
        // we fake the event, because we've probably been ignoring it for a while
        if ( [_compressedDataStream hasBytesAvailable] )
            [self stream: _compressedDataStream handleEvent: NSStreamEventHasBytesAvailable];
    }/*
    else
    {
        // read the amount requested, setup variables in the zlib stream
        [_internal readOutputToBuffer: buffer + totalRead length: len];
        totalRead += len;
        
        [_internal setStatusForStream: _compressedDataStream];
    }*/
    else if ( _internal.outputAvailable > 0 )
    {
        // there's more data left to be read, so we'll post another event
        [_internal postStreamEvent: NSStreamEventHasBytesAvailable];
    }
    
    if ( _internal.status == NSStreamStatusReading )
        _internal.status = NSStreamStatusOpen;
    
    return ( totalRead );
}

- (BOOL) getBuffer: (uint8_t **) buffer length: (NSUInteger *) len
{
    // sorry, but we need to do buffer management when the caller reads stuff out
    return ( NO );
}

- (BOOL) hasBytesAvailable
{
    return ( _internal.outputAvailable > 0 );
}

- (id) propertyForKey: (NSString *) key
{
    return ( [_compressedDataStream propertyForKey: key] );
}

- (void) setProperty: (id) property forKey: (NSString *) key
{
    [_compressedDataStream setProperty: property forKey: key];
}

@end
