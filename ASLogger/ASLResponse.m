/*
 *  ASLResponse.m
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

#import "ASLResponse.h"
#import "ASLMessage.h"
#import "ASLQuery.h"

// keep in sync with ASLMessage.m
@interface ASLMessage (ResponseHelper)
- (id) initWithResponseMessage: (aslmsg) message;	// doesn't call aslmsg_free()
@end

@implementation ASLResponse

@synthesize response=_response;

+ (ASLResponse *) responseFromQuery: (ASLQuery *) query
{
	aslresponse r = asl_search( NULL, query.aslmessage );
	if ( r == NULL )
		return ( nil );
	return ( [[[self alloc] initWithResponse: r] autorelease] );
}

+ (ASLResponse *) responseWithResponse: (aslresponse) response
{
	return ( [[[self alloc] initWithResponse: response] autorelease] );
}

- (id) initWithResponse: (aslresponse) response
{
	if ( [super init] == nil )
		return ( nil );
	
	_response = response;
	
	return ( self );
}

- (void) dealloc
{
	aslresponse_free( _response );
	[super dealloc];
}

- (void) finalize
{
	aslresponse_free( _response );
	[super finalize];
}

- (ASLMessage *) next
{
	aslmsg m = aslresponse_next( _response );
	if ( m == NULL )
		return ( nil );
	return ( [[[ASLMessage alloc] initWithResponseMessage: m] autorelease] );
}

@end
