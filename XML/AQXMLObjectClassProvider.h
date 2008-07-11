/*
 *  AQXMLObjectClassProvider.h
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

#import <Foundation/NSObject.h>

@protocol AQXMLObjectClassProvider <NSObject>
- (Class) classForTagName: (NSString *) tagName;
@end