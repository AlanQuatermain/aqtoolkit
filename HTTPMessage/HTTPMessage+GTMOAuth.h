//
//  HTTPMessage+GTMOAuth.h
//  My Xero Status
//
//  Created by Mark Aufflick on 2/08/12.
//  Copyright (c) 2012 Pumptheory. All rights reserved.
//

#import "HTTPMessage.h"

#import "GTMOAuthAuthentication.h"

@interface HTTPMessage (GTMOAuth)

- (void)authorizeWithGTMOAuth:(GTMOAuthAuthentication *)oauth;

@end
