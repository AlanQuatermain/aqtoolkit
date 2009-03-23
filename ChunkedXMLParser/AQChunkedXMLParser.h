/*
 *  AQChunkedXMLParser.h
 *  AQToolkit
 *
 *  Created by Jim Dovey on 21/02/2009.
 *  Copyright (c) 2009 Jim Dovey. Some Rights Reserved.
 *
 *  This work is licensed under a Creative Commons
 *  Attribution License. You are free to use, modify,
 *  and redistribute this work, provided you include
 *  the following disclaimer:
 *
 *    Portions Copyright (c) 2009 Jim Dovey
 *
 *  For license details, see:
 *    http://creativecommons.org/licenses/by/3.0/
 *
 */

#import <Cocoa/Cocoa.h>
#import "AQChunkedXMLData.h"

// this subclass overrides only the two functions provided here
// the URL initializer will create a stream + chunked data & call -initWithData:
@interface AQChunkedXMLParser : NSXMLParser

- (id) initWithContentsOfURL: (NSURL *) url;
- (BOOL) parse;

@end
