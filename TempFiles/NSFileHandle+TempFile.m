/*
 * NSFileHandle+TempFile.m
 * AQToolkit
 * 
 * Created by Jim Dovey on 10/4/2009.
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

#import "NSFileHandle+TempFile.h"
#import <sys/fcntl.h>
#import <sys/param.h>

static NSMutableSet * __tempFileStore = nil;

@implementation NSFileHandle (AQTempFile)

+ (void) initializeTempFileStore
{
    if ( __tempFileStore != nil )
        return;
    
    // double-checked locking can bite you. This routine is designed for
    //  rare use, so it shouldn't be a problem here, but to understand
    //  why it's often a bad idea, look here:
    //  http://www.aristeia.com/Papers/DDJ_Jul_Aug_2004_revised.pdf
    @synchronized(self)
    {
        if ( __tempFileStore == nil )
            __tempFileStore = [[NSMutableSet alloc] init];
    }
}

+ (NSFileHandle *) tempFile
{
    return ( [[[self alloc] initTempFile] autorelease] );
}

+ (NSFileHandle *) tempFileInFolder: (NSString *) folderPath
{
    return ( [[[self alloc] initTempFileInFolder: folderPath] autorelease] );
}

+ (NSFileHandle *) tempFileUnderSubfolder: (NSString *) folderName
{
    return ( [[[self alloc] initTempFileUnderSubfolder: folderName] autorelease] );
}

- (id) initTempFile
{
    return ( [self initTempFileInFolder: [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSProcessInfo processInfo] processName]]] );
}

- (id) initTempFileInFolder: (NSString *) folderPath
{
    NSString * path = [folderPath stringByAppendingPathComponent: @"XXXXXXXXXXXX"];
    char cStr[PATH_MAX];
    strlcpy( cStr, [path fileSystemRepresentation], PATH_MAX );
    
    int fd = mkstemp( cStr );
    if ( fd == -1 )
        return ( nil );
    
    [[self class] initializeTempFileStore];
    
    @synchronized(__tempFileStore)
    {
        [__tempFileStore addObject: [NSString stringWithUTF8String: cStr]];
    }
    
    return ( [self initWithFileDescriptor: fd] );
}

- (id) initTempFileUnderSubfolder: (NSString *) folderName
{
    return ( [self initTempFileInFolder: [NSTemporaryDirectory() stringByAppendingPathComponent: folderName]] );
}

- (NSString *) filePath
{
    int fd = [self fileDescriptor];
    if ( fd == -1 )
        return ( nil );
    
    char buf[MAXPATHLEN];
    buf[0] = '\0';
    
    int err = fcntl( fd, F_GETPATH, buf );
    if ( err == -1 )
        return ( nil );
    
    if ( buf[0] == '\0' )
        return ( nil );
    
    return ( [NSString stringWithUTF8String: buf] );
}

+ (void) deleteTemporaryFiles
{
    if ( __tempFileStore == nil )
        return;
    
    @synchronized(__tempFileStore)
    {
        NSFileManager * fm = [NSFileManager defaultManager];
        
        for ( NSString * path in [__tempFileStore allObjects] )
        {
            [fm removeItemAtPath: path error: NULL];
        }
        
        [__tempFileStore removeAllObjects];
    }
}

@end
