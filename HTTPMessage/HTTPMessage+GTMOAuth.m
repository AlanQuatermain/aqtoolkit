//
//  HTTPMessage+GTMOAuth.m
//  My Xero Status
//
//  Created by Mark Aufflick on 2/08/12.
//  Copyright (c) 2012 Pumptheory. All rights reserved.
//

#import "HTTPMessage+GTMOAuth.h"

@implementation HTTPMessage (GTMOAuth)

- (void)authorizeWithGTMOAuth:(GTMOAuthAuthentication *)oauth
{
    NSMutableURLRequest * requestCopy = [[self urlRequestRepresentation] mutableCopy];
    [oauth authorizeRequest:requestCopy];
    
    NSDictionary * headers = requestCopy.allHTTPHeaderFields;
    for (NSString * key in [headers allKeys])
        [self setValue:headers[key] forHeaderField:key];
}

@end
