/*
 *  ASLQuery.m
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

#import "ASLQuery.h"
#import "NSData+Base64.h"

@implementation ASLQuery

- (id) init
{
	// hacky: -[NSObject init] doesn't appear to do anything except return self, and
	//  -[ASLMessage init] creates a 'message' type of aslmsg, which we would otherwise
	//  need to free. So, I'm forgoing the call to [super init] altogether. Fingers crossed...
	_message = asl_new( ASL_TYPE_QUERY );
	return ( self );
}

- (void) setValue: (id) value forKey: (NSString *) key withOperation: (ASLQueryOperation) operation
{
	if ( (value == nil) || ([value isKindOfClass: [NSNull class]]) )
	{
		asl_unset( _message, [key UTF8String] );
		return;
	}
	
	if ( [value isKindOfClass: [NSString class]] )
	{
		asl_set_query( _message, [key UTF8String], [value UTF8String], operation );
	}
	else if ( [value respondsToSelector: @selector(stringValue)] )
	{
		asl_set_query( _message, [key UTF8String], [[value stringValue] UTF8String], operation );
	}
	else if ( [value isKindOfClass: [NSData class]] )
	{
		asl_set_query( _message, [key UTF8String], 
					   [[value base64EncodedString] UTF8String],  operation );
	}
	else
	{
		asl_set_query( _message, [key UTF8String], [[value stringValue] UTF8String], operation );
	}
}

@end
