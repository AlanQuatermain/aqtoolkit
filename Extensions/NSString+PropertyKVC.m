/*
 *  NSString+PropertyKVC.m
 *  AQToolkit
 *
 *  Created by Jim Dovey on 27/8/2008.
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

#import "NSString+PropertyKVC.h"

@implementation NSString (AQPropertyKVC)

- (NSString *) propertyStyleString
{
    NSString * result = [[self substringToIndex: 1] lowercaseString];
    if ( [self length] == 1 )
        return ( result );

    return ( [result stringByAppendingString: [self substringFromIndex: 1]] );
}

@end
