//
//  NSStream+HTTPMessage.h
//  Kobov3
//
//  Created by Jim Dovey on 10-04-08.
//  Copyright 2010 Kobo Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTTPMessage.h"

@interface NSStream (HTTPMessage)

- (HTTPMessage *) finalRequestMessage;
- (HTTPMessage *) responseMessageHeader;

- (NSURL *) finalURL;

@end
