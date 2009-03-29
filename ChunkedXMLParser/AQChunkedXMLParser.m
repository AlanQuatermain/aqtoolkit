/*
 *  AQChunkedXMLData.m
 *  AQToolkit
 *
 *  Created by Jim Dovey on 21/02/2009.
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
