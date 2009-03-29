/*
 *  ASLResponse.m
 *  AQToolkit
 *
 *  Created by Jim Dovey on 31/8/2008.
 *
 *  Copyright (c) 2008-2009, Jim Dovey
 *  All rights reserved.
 *  
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *
 *  Redistributions of source code must retain the above copyright notice,
 *  this list of conditions and the following disclaimer.
 *  
 *  Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *  
 *  Neither the name of this project's author nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
 *  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 *  HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 *  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 *  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
