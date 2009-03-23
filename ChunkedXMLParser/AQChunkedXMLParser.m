/*
 *  AQChunkedXMLData.m
 *  AQToolkit
 *
 *  Created by Jim Dovey on 21/02/2009.
 *  Copyright (c) 2009 Jim Dovey. Some Rights Reserved.
 *
 *  This work is licensed under a Creative Commons
 *  Attribution License. You are free to use, modify,
 *  and redistribute this work, provided you include
 *  the following disclaimer:
 *
 *    Portions Copyright (c) 2009 Jim Dovey
 *
 *  For license details, see:
 *    http://creativecommons.org/licenses/by/3.0/
 *
 */

#import "AQChunkedXMLParser.h"
#import <libxml/parser.h>		// add /usr/include/libxml2 to header search paths

// this is what the NSXMLParser really has inside it
/*
@interface NSXMLParser : NSObject
{
	void *				_parser;
	id					_delegate;
	_NSXMLParserInfo *	_reserved1;
	NSData *			_reserved2;
	NSMutableArray *	_reserved3;
}
*/

// from this object we only use the first two instance variables
@interface _NSXMLParserInfo : NSObject
{
	@public
	xmlSAXHandlerPtr	saxHandler;
	xmlParserCtxtPtr	parserContext;
	unsigned int		parserFlags;
	NSError *			error;
	NSMutableArray *	namespaces;
	BOOL				delegateAborted;
}
@end

@interface NSXMLParser ()
- (void) _setParserError: (int) xmlErr;
@end

@interface NSXMLParser (AQChunkedParserAccessorMethods)
- (_NSXMLParserInfo *) aq__parserInfo;
- (AQChunkedXMLData *) aq__data;
@end

@implementation NSXMLParser (AQChunkedParserAccessorMethods)

- (_NSXMLParserInfo *) aq__parserInfo
{
	return ( (_NSXMLParserInfo *)_reserved1 );
}

- (AQChunkedXMLData *) aq__data
{
	return ( (AQChunkedXMLData *)_reserved2 );
}

@end

#pragma mark -

@implementation AQChunkedXMLParser

- (id) initWithContentsOfURL: (NSURL *) url
{
	if ( [url isFileURL] )
	{
		AQChunkedXMLData * data = [AQChunkedXMLData dataWithContentsOfFile: [url path]];
		return ( [self initWithData: data] );
	}
	else if ( [[url scheme] isEqualToString: @"ftp"] )
	{
		CFReadStreamRef stream = CFReadStreamCreateWithFTPURL( kCFAllocatorDefault, (CFURLRef)url );
		AQChunkedXMLData * data = [AQChunkedXMLData dataFromStream: NSMakeCollectable(stream)];
		CFRelease( stream );
		return ( [self initWithData: data] );
	}
		
	NSLog( @"AQChunkedXMLParser initialized with %@ URL, not using chunked data", [url scheme] );
	return ( [super initWithContentsOfURL: url] );
}

- (BOOL) parse
{
	// fallback to standard if we don't have a chunked data object
	if ( [[self aq__data] isKindOfClass: [AQChunkedXMLData class]] == NO )
		return ( [super parse] );
	
	// a cast to ensure the pointer indirection works without the compiler bitching
	_NSXMLParserInfo * info = [self aq__parserInfo];
	AQChunkedXMLData * data = [self aq__data];
	
	xmlSAXHandlerPtr saxHandler = NULL;
	if ( [self delegate] != nil )
		saxHandler = info->saxHandler;
	
	info->parserContext = xmlCreatePushParserCtxt( saxHandler, self, [data bytes],
												   [data length], NULL );
	
	int options = [self shouldResolveExternalEntities] ? XML_PARSE_RECOVER|XML_PARSE_NOENT|XML_PARSE_DTDLOAD : XML_PARSE_RECOVER|XML_PARSE_DTDATTR;
	if ( saxHandler == NULL )
		options |= XML_PARSE_NOERROR|XML_PARSE_NOWARNING;
	
	xmlCtxtUseOptions( info->parserContext, options );
	
	// now the changes: we loop through the chunks of data, parsing each chunk in turn
	if ( [data getNextChunk] == NO )
		return ( YES );
	
	while ( [data length] != 0 )
	{
		int err = xmlParseChunk( info->parserContext, [data bytes], [data length],
								 [data getNextChunk] ? 0 : 1 );
		if ( err == -1 )
		{
			[self _setParserError: err];
			return ( NO );
		}
	}
	
	return ( YES );
}

@end
