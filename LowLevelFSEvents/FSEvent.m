/*
 *  FSEvent.m
 *  AQToolkit
 *
 *  Created by Jim Dovey on 19/02/2009.
 *
 *  Copyright (c) 2009, Jim Dovey
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

#import "FSEvent.h"

@implementation FSEvent

@synthesize eventCode=_eventCode;
@synthesize processID=_processID;
@synthesize timestamp=_timestamp;

- (id) init
{
	if ( [super init] == nil )
		return ( nil );
	
	_arguments = [[NSMutableDictionary alloc] init];
	
	return ( self );
}

- (void) dealloc
{
	[_arguments release];
	[super dealloc];
}

- (NSDictionary *) arguments
{
	return ( [[_arguments copy] autorelease] );
}

+ (NSString *) stringForEventCode: (FSEventCode) code
{
	switch ( code )
	{
		case FSEventCreateFile:
			return ( @"Create File" );
			
		case FSEventDelete:
			return ( @"Delete" );
			
		case FSEventStateChanged:
			return ( @"State Changed" );
			
		case FSEventRename:
			return ( @"Rename" );
			
		case FSEventContentModified:
			return ( @"Content Modified" );
			
		case FSEventExchange:
			return ( @"Exchange Files" );
			
		case FSEventFinderInfoChanged:
			return ( @"Finder Info Changed" );
			
		case FSEventCreateFolder:
			return ( @"Create Folder" );
			
		case FSEventChangeOwner:
			return ( @"Change Owner" );
			
		case FSEventXAttrModified:
			return ( @"Extended Attribute Modified" );
			
		case FSEventXAttrRemoved:
			return ( @"Extended Attribute Removed" );
			
		default:
			break;
	}
	
	return ( @"<Unknown Event>" );
}

@end
