/*
 *  AQXMLObjectReader.h
 *  XML Object Parser
 *
 *  Created by Jim Dovey on 7/7/2008.
 *  Copyright (c) 2008 Jim Dovey. Some Rights Reserved.
 *
 *  This work is licensed under a Creative Commons
 *  Attribution-Noncommercial-Share Alike License. You are
 *  free to use and redistribute this work, but may not use
 *  it for commercial purposes, and any changes you make
 *  must be released under the same or similar license.
 *  In addition, you must include the following disclaimer:
 *
 *    Portions Copyright (c) 2008 Jim Dovey
 *
 *  For license details, see:
 *    http://creativecommons.org/licenses/by-nc-sa/3.0/
 *
 */

#import <Foundation/Foundation.h>
#import "AQXMLObjectClassProvider.h"

@interface AQXMLObjectReader : NSObject
{
	id<AQXMLObjectClassProvider>	_classProvider	__weak;
	NSMutableArray *				_objectStack;	
	id								_parsedObject;
}

@property(nonatomic, readonly) id parsedObject;

// this will create a reader and assign it as the delegate of an XML parser
+ (id) parseXMLDocument: (NSXMLDocument *) document 
	 usingClassProvider: (id<AQXMLObjectClassProvider>) classProvider;

// this is the designated initializer -- a valid class provider is required
- (id) initWithProvider: (id<AQXMLObjectClassProvider>) provider;

// parse the given document and return a root object
// this invalidates any root object currently held by the receiver
- (id) parseXMLDocument: (NSXMLDocument *) document;

// all remaining intricacies are internal

@end
