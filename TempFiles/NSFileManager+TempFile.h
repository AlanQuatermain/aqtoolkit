/*
 * NSFileManager+TempFile.h
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

#import <Foundation/Foundation.h>

/*!
    @category   AQTempFileSupport
    @abstract   Routines to generate temporary file paths.
*/
@interface NSFileManager (AQTempFileSupport)

/*!
    @method
    @abstract   Returns a path for a new temporary file.
    @discussion
    The returned path is based on NSTemporaryDirectory()/#{appName}/#{tempName}.
*/
- (NSString *) tempFilePath;

/*!
    @method
    @abstract   Append a temp file name to the given path.
    @param folderPath Path to the parent folder of the new temp file.
    @discussion
    The returned path is based on folderPath/#{tempName}.
*/
- (NSString *) tempFileInFolder: (NSString *) folderPath;

/*!
    @method     
    @abstract   Create a temporary file inside NSTemporaryDirectory(), inside a given folder.
    @param folderName The name of the subfolder of NSTemporaryDirectory() in which to create the temp file.
    @discussion
    The returned path is based on NSTemporaryDirectory()/folderName/#{tempName}
*/
- (NSString *) tempFileUnderSubfolder: (NSString *) folderName;

@end
