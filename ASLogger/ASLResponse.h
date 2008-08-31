/*
 *  ASLResponse.h
 *  AQToolkit
 *
 *  Created by Jim Dovey on 31/8/2008.
 *  Copyright (c) 2008 Jim Dovey. Some Rights Reserved.
 *
 *  This work is licensed under a Creative Commons
 *  Attribution License. You are free to use, modify,
 *  and redistribute this work, but may only distribute
 *  the resulting work under the same, similar or a
 *  compatible license. In addition, you must include
 *  the following disclaimer:
 *
 *    Portions Copyright (c) 2008 Jim Dovey
 *
 *  For license details, see:
 *    http://creativecommons.org/licenses/by-sa/3.0/
 *
 */

#import <Foundation/Foundation.h>
#import <asl.h>

@class ASLMessage, ASLQuery;

@interface ASLResponse : NSObject
{
	aslresponse	_response;
}

@property (nonatomic, readonly) aslresponse response;

+ (ASLResponse *) responseFromQuery: (ASLQuery *) query;
+ (ASLResponse *) responseWithResponse: (aslresponse) response;
- (id) initWithResponse: (aslresponse) response;

- (ASLMessage *) next;

@end
