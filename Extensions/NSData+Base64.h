/*
 *  NSData+Base64.h
 *  AQToolkit
 *
 *  Created by Jim Dovey on 31/8/2008.
 *  Copyright (c) 2008 Jim Dovey. Some Rights Reserved.
 *
 *  This work is licensed under a Creative Commons
 *  Attribution License. You are free to use, modify,
 *  and redistribute this work, provided you include
 *  the following disclaimer:
 *
 *    Portions Copyright (c) 2008 Jim Dovey
 *
 *  For license details, see:
 *    http://creativecommons.org/licenses/by/3.0/
 *
 */

#import <Foundation/NSData.h>

@class NSString;

@interface NSData (Base64)

+ (NSData *) dataFromBase64String: (NSString *) base64String;
- (id) initWithBase64String: (NSString *) base64String;
- (NSString *) base64EncodedString;

@end
