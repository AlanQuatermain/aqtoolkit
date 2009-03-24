/*
 *  NSError+CFStreamError.h
 *  AQToolkit
 *
 *  Created by Jim Dovey on 24/3/2009.
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

#import <Foundation/NSError.h>
#import <CoreFoundation/CFStream.h>

@interface NSError (CFStreamErrorConversion)
+ (NSError *) errorFromCFStreamError: (CFStreamError) streamError;
@end
