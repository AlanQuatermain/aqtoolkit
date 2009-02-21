//
//  AQChunkedXMLParser.h
//  AQToolkit
//
//  Created by Jim Dovey on 21/02/09.
//  Copyright 2009 Morfunk, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AQChunkedXMLData.h"

// this subclass overrides only the two functions provided here
// the URL initializer will create a stream + chunked data & call -initWithData:
@interface AQChunkedXMLParser : NSXMLParser

- (id) initWithContentsOfURL: (NSURL *) url;
- (BOOL) parse;

@end
