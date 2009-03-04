/*
 *  FSEvent.m
 *  AQToolkit
 *
 *  Created by Jim Dovey on 19/02/2009.
 *  Copyright (c) 2009 Jim Dovey. Some Rights Reserved.
 *
 *  This work is licensed under a Creative Commons
 *  Attribution License. You are free to use, modify,
 *  and redistribute this work, but may only distribute
 *  the resulting work under the same, similar or a
 *  compatible license. In addition, you must include
 *  the following disclaimer:
 *
 *    Portions Copyright (c) 2009 Jim Dovey
 *
 *  For license details, see:
 *    http://creativecommons.org/licenses/by-sa/3.0/
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
