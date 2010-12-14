//
//  AQXMLParserWithTimeout.h
//  Kobov3
//
//  Created by Jim Dovey on 10-04-08.
//  Copyright 2010 Kobo Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AQXMLParser.h"

extern const NSTimeInterval KBDefaultXMLParserTimeout;

@interface AQXMLParserWithTimeout : AQXMLParser
{
	NSTimer *		_timeoutTimer;
	NSTimeInterval	_timeoutInterval;
}
@property (nonatomic, assign) NSTimeInterval timeout;
@end
