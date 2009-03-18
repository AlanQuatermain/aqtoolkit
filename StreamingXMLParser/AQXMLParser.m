/*
 *  AQXMLParser.h
 *  AQToolkit
 *
 *  Created by Jim Dovey on 17/3/2009.
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

/* -I/usr/include/libxml -lxml */

#import "AQXMLParser.h"

#import <libxml/parser.h>
#import <libxml/parserInternals.h>
#import <libxml/SAX2.h>
#import <libxml/xmlerror.h>
#import <libxml/encoding.h>
#import <libxml/entities.h>

@interface _AQXMLParserInternal : NSObject
{
	@public
	xmlSAXHandlerPtr	saxHandler;
	xmlParserCtxtPtr	parserContext;
	NSUInteger			parserFlags;
	NSError *			error;
	NSMutableArray *	namespaces;
	BOOL				delegateAborted;
}
@end

@implementation _AQXMLParserInternal
@end

enum
{
	AQXMLParserShouldProcessNamespaces	= 1<<0,
	AQXMLParserShouldReportPrefixes		= 1<<1,
	AQXMLParserShouldResolveExternals	= 1<<2
	
};

@interface AQXMLParser (Internal)
- (void) _setParserError: (int) err;
- (xmlParserCtxtPtr) _parserContext;
- (void) _pushNamespaces: (NSDictionary *) nsDict;
- (void) _popNamespaces;
- (void) _initializeSAX2Callbacks;
- (_AQXMLParserInternal *) _info;
@end

#pragma mark -

static inline NSString * NSStringFromXmlChar( const xmlChar * ch )
{
	if ( ch == NULL )
		return ( nil );
	
	return ( [[NSString allocWithZone: nil] initWithBytes: ch
												   length: strlen((const char *)ch)
												 encoding: NSUTF8StringEncoding] );
}

static inline NSString * AttributeTypeString( int type )
{
#define TypeCracker(t) case XML_ATTRIBUTE_ ## t: return @#t
	switch ( type )
	{
		TypeCracker(CDATA);
		TypeCracker(ID);
		TypeCracker(IDREF);
		TypeCracker(IDREFS);
		TypeCracker(ENTITY);
		TypeCracker(ENTITIES);
		TypeCracker(NMTOKEN);
		TypeCracker(NMTOKENS);
		TypeCracker(ENUMERATION);
		TypeCracker(NOTATION);
			
		default:
			break;
	}
	
	return ( @"" );
}

static int __isStandalone( void * ctx )
{
	AQXMLParser * parser = (AQXMLParser *) ctx;
	xmlParserCtxtPtr p = [parser _parserContext];
	return ( p->myDoc->standalone );
}

static int __hasInternalSubset2( void * ctx )
{
	AQXMLParser * parser = (AQXMLParser *) ctx;
	xmlParserCtxtPtr p = [parser _parserContext];
	return ( p->myDoc->intSubset == NULL ? 0 : 1 );
}

static int __hasExternalSubset2( void * ctx )
{
	AQXMLParser * parser = (AQXMLParser *) ctx;
	xmlParserCtxtPtr p = [parser _parserContext];
	return ( p->myDoc->extSubset == NULL ? 0 : 1 );
}

static void __internalSubset2( void * ctx, const xmlChar * name, const xmlChar * ElementID,
							   const xmlChar * SystemID )
{
	AQXMLParser * parser = (AQXMLParser *) ctx;
	xmlParserCtxtPtr p = [parser _parserContext];
	xmlSAX2InternalSubset( p, name, ElementID, SystemID );
}

static void __externalSubset2( void * ctx, const xmlChar * name, const xmlChar * ExternalID,
							   const xmlChar * SystemID )
{
	AQXMLParser * parser = (AQXMLParser *) ctx;
	xmlParserCtxtPtr p = [parser _parserContext];
	xmlSAX2ExternalSubset( p, name, ExternalID, SystemID );
}

static xmlParserInputPtr __resolveEntity( void * ctx, const xmlChar * publicId, const xmlChar * systemId )
{
	AQXMLParser * parser = (AQXMLParser *) ctx;
	xmlParserCtxtPtr p = [parser _parserContext];
	return ( xmlSAX2ResolveEntity(p, publicId, systemId) );
}

static void __characters( void * ctx, const xmlChar * ch, int len )
{
	AQXMLParser * parser = (AQXMLParser *) ctx;
	xmlParserCtxtPtr p = [parser _parserContext];
	
	if ( (int)(p->_private) == 1 )
	{
		p->_private = 0;
		return;
	}
	
	id<AQXMLParserDelegate> delegate = parser.delegate;
	if ( [delegate respondsToSelector: @selector(parser:foundCharacters:)] == NO )
		return;
	
	NSString * str = [[NSString allocWithZone: nil] initWithBytes: ch
														   length: len
														 encoding: NSUTF8StringEncoding];
	[delegate parser: parser foundCharacters: str];
	[str release];
}

static xmlEntityPtr __getParameterEntity( void * ctx, const xmlChar * name )
{
	AQXMLParser * parser = (AQXMLParser *) ctx;
	xmlParserCtxtPtr p = [parser _parserContext];
	return ( xmlSAX2GetParameterEntity(p, name) );
}

static void __entityDecl( void * ctx, const xmlChar * name, int type, const xmlChar * publicId,
						  const xmlChar * systemId, xmlChar * content )
{
	AQXMLParser * parser = (AQXMLParser *) ctx;
	xmlParserCtxtPtr p = [parser _parserContext];
	id<AQXMLParserDelegate> delegate = parser.delegate;
	
	xmlSAX2EntityDecl( p, name, type, publicId, systemId, content );
	
	NSString * contentStr = NSStringFromXmlChar( content );
	NSString * nameStr = NSStringFromXmlChar( name );
	
	if ( [contentStr length] != 0 )
	{
		if ( [delegate respondsToSelector: @selector(parser:foundInternalEntityDeclarationWithName:value:)] )
			[delegate parser: parser foundInternalEntityDeclarationWithName: nameStr value: contentStr];
	}
	else if ( [parser shouldResolveExternalEntities] )
	{
		if ( [delegate respondsToSelector: @selector(parser:foundExternalEntityDeclarationWithName:publicID:systemID:)] )
		{
			NSString * publicIDStr = NSStringFromXmlChar(publicId);
			NSString * systemIDStr = NSStringFromXmlChar(systemId);
			
			[delegate parser: parser foundExternalEntityDeclarationWithName: nameStr
					publicID: publicIDStr systemID: systemIDStr];
			
			[publicIDStr release];
			[systemIDStr release];
		}
	}
	
	[contentStr release];
	[nameStr release];
}

static void __attributeDecl( void * ctx, const xmlChar * elem, const xmlChar * fullname, int type, int def,
							 const xmlChar * defaultValue, xmlEnumerationPtr tree )
{
	AQXMLParser * parser = (AQXMLParser *) ctx;
	id<AQXMLParserDelegate> delegate = parser.delegate;
	
	if ( [delegate respondsToSelector: @selector(parser:foundAttributeDeclarationWithName:forElement:type:defaultValue:)] == NO )
		return;
	
	NSString * elemStr = NSStringFromXmlChar(elem);
	NSString * fullnameStr = NSStringFromXmlChar(fullname);
	NSString * defaultStr = NSStringFromXmlChar(defaultValue);
	
	[delegate parser: parser foundAttributeDeclarationWithName: fullnameStr forElement: elemStr
				type: AttributeTypeString(type) defaultValue: defaultStr];
	
	[elemStr release];
	[fullnameStr release];
	[defaultStr release];
}

static void __elementDecl( void * ctx, const xmlChar * name, int type, xmlElementContentPtr content )
{
	AQXMLParser * parser = (AQXMLParser *) ctx;
	id<AQXMLParserDelegate> delegate = parser.delegate;
	
	if ( [delegate respondsToSelector: @selector(parser:foundElementDeclarationWithName:model:)] == NO )
		return;
	
	NSString * nameStr = NSStringFromXmlChar(name);
	[delegate parser: parser foundElementDeclarationWithName: nameStr model: @""];
	[nameStr release];
}

static void __notationDecl( void * ctx, const xmlChar * name, const xmlChar * publicId, const xmlChar * systemId )
{
	AQXMLParser * parser = (AQXMLParser *) ctx;
	id<AQXMLParserDelegate> delegate = parser.delegate;
	
	if ( [delegate respondsToSelector: @selector(parser:foundNotationDeclarationWithName:publicID:systemID:)] == NO )
		return;
	
	NSString * nameStr = NSStringFromXmlChar(name);
	NSString * publicIDStr = NSStringFromXmlChar(publicId);
	NSString * systemIDStr = NSStringFromXmlChar(systemId);
	
	[delegate parser: parser foundNotationDeclarationWithName: nameStr
			publicID: publicIDStr systemID: systemIDStr];
	
	[nameStr release];
	[publicIDStr release];
	[systemIDStr release];
}

static void __unparsedEntityDecl( void * ctx, const xmlChar * name, const xmlChar * publicId,
								  const xmlChar * systemId, const xmlChar * notationName )
{
	AQXMLParser * parser = (AQXMLParser *) ctx;
	xmlParserCtxtPtr p = [parser _parserContext];
	id<AQXMLParserDelegate> delegate = parser.delegate;
	
	xmlSAX2UnparsedEntityDecl( p, name, publicId, systemId, notationName );
	
	if ( [delegate respondsToSelector: @selector(parser:foundUnparsedEntityDeclarationWithName:publicID:systemID:notationName:)] == NO )
		return;
	
	NSString * nameStr = NSStringFromXmlChar(name);
	NSString * publicIDStr = NSStringFromXmlChar(publicId);
	NSString * systemIDStr = NSStringFromXmlChar(systemId);
	NSString * notationNameStr = NSStringFromXmlChar(notationName);
	
	[delegate parser: parser foundUnparsedEntityDeclarationWithName: nameStr
			publicID: publicIDStr systemID: systemIDStr notationName: notationNameStr];
	
	[nameStr release];
	[publicIDStr release];
	[systemIDStr release];
	[notationNameStr release];
}

static void __startDocument( void * ctx )
{
	AQXMLParser * parser = (AQXMLParser *) ctx;
	xmlParserCtxtPtr p = [parser _parserContext];
	id<AQXMLParserDelegate> delegate = parser.delegate;
	
	const char * encoding = (const char *) p->encoding;
	if ( encoding == NULL )
		encoding = (const char *) p->input->encoding;
	
	if ( encoding != NULL )
		xmlSwitchEncoding( p, xmlParseCharEncoding(encoding) );
	
	xmlSAX2StartDocument( p );
	
	if ( [delegate respondsToSelector: @selector(parserDidStartDocument:)] == NO )
		return;
	
	[delegate parserDidStartDocument: parser];
}

static void __endDocument( void * ctx )
{
	AQXMLParser * parser = (AQXMLParser *) ctx;
	id<AQXMLParserDelegate> delegate = parser.delegate;
	
	if ( [delegate respondsToSelector: @selector(parserDidEndDocument:)] == NO )
		return;
	
	[delegate parserDidEndDocument: parser];
}

static void __endElementNS( void * ctx, const xmlChar * localname, const xmlChar * prefix, const xmlChar * URI )
{
	AQXMLParser * parser = (AQXMLParser *) ctx;
	id<AQXMLParserDelegate> delegate = parser.delegate;
	
	NSString * prefixStr = nil;
	
	if ( [parser shouldProcessNamespaces] )
		prefixStr = NSStringFromXmlChar(prefix);
	
	NSString * localnameStr = NSStringFromXmlChar(localname);
	
	NSString * completeStr = nil;
	if ( [prefixStr length] != 0 )
		completeStr = [[[NSString alloc] initWithFormat: @"%@:%@", prefixStr, localnameStr] autorelease];
	else
		completeStr = [[localnameStr retain] autorelease];
	
	NSString * uriStr = NSStringFromXmlChar(URI);
	
	if ( [delegate respondsToSelector: @selector(parser:didEndElement:namespaceURI:qualifiedName:)] )
	{
		if ( prefixStr != nil )
		{
			if ( (completeStr == nil) && (uriStr == nil) )
				uriStr = @"";
			
			[delegate parser: parser didEndElement: localnameStr
				namespaceURI: uriStr qualifiedName: completeStr];
		}
		else
		{
			[delegate parser: parser didEndElement: localnameStr
				namespaceURI: nil qualifiedName: nil];
		}
	}
	
	[parser _popNamespaces];
	
	[prefixStr release];
	[localnameStr release];
	[uriStr release];
}

static void __processingInstruction( void * ctx, const xmlChar * target, const xmlChar * data )
{
	AQXMLParser * parser = (AQXMLParser *) ctx;
	id<AQXMLParserDelegate> delegate = parser.delegate;
	
	if ( [delegate respondsToSelector: @selector(parser:foundProcessingInstructionWithTarget:data:)] == NO )
		return;
	
	NSString * targetStr = NSStringFromXmlChar(target);
	NSString * dataStr = NSStringFromXmlChar(data);
	
	[delegate parser: parser foundProcessingInstructionWithTarget: targetStr data: dataStr];
	
	[targetStr release];
	[dataStr release];
}

static void __cdataBlock( void * ctx, const xmlChar * value, int len )
{
	AQXMLParser * parser = (AQXMLParser *) ctx;
	id<AQXMLParserDelegate> delegate = parser.delegate;
	
	if ( [delegate respondsToSelector: @selector(parser:foundCDATA:)] == NO )
		return;
	
	NSData * data = [[NSData allocWithZone: nil] initWithBytes: value length: len];
	[delegate parser: parser foundCDATA: data];
	[data release];
}

static void __comment( void * ctx, const xmlChar * value )
{
	AQXMLParser * parser = (AQXMLParser *) ctx;
	id<AQXMLParserDelegate> delegate = parser.delegate;
	
	if ( [delegate respondsToSelector: @selector(parser:foundComment:)] == NO )
		return;
	
	NSString * commentStr = NSStringFromXmlChar(value);
	[delegate parser: parser foundComment: commentStr];
	[commentStr release];
}

static void __errorCallback( void * ctx, const char * msg, ... )
{
	AQXMLParser * parser = (AQXMLParser *) ctx;
	xmlParserCtxtPtr p = [parser _parserContext];
	id<AQXMLParserDelegate> delegate = parser.delegate;
	
	if ( [delegate respondsToSelector: @selector(parser:parseErrorOccurred:)] == NO )
		return;
	
	[delegate parser: parser parseErrorOccurred: [NSError errorWithDomain: NSXMLParserErrorDomain
																	 code: p->errNo
																 userInfo: nil]];
}

static void __structuredErrorFunc( void * ctx, xmlErrorPtr errorData )
{
	AQXMLParser * parser = (AQXMLParser *) ctx;
	id<AQXMLParserDelegate> delegate = parser.delegate;
	_AQXMLParserInternal * info = [parser _info];
	
	if ( [delegate respondsToSelector: @selector(parser:parseErrorOccurred:)] == NO )
		return;
	
	int code = (info->delegateAborted ? 0x200 : errorData->code);
	[delegate parser: parser parseErrorOccurred: [NSError errorWithDomain: NSXMLParserErrorDomain
																	 code: code
																 userInfo: nil]];
}

static xmlEntityPtr __getEntity( void * ctx, const xmlChar * name )
{
	AQXMLParser * parser = (AQXMLParser *) ctx;
	xmlParserCtxtPtr p = [parser _parserContext];
	id<AQXMLParserDelegate> delegate = parser.delegate;
	
	xmlEntityPtr entity = xmlGetPredefinedEntity( name );
	if ( entity != NULL )
		return ( entity );
	
	entity = xmlSAX2GetEntity( p, name );
	if ( entity != NULL )
	{
		if ( p->instate & XML_PARSER_MISC|XML_PARSER_PI|XML_PARSER_DTD )
			p->_private = (void *) 1;
		return ( entity );
	}
	
	if ( [delegate respondsToSelector: @selector(parser:resolveExternalEntityName:systemID:)] == NO )
		return ( NULL );
	
	NSString * nameStr = NSStringFromXmlChar(name);
	
	NSData * data = [delegate parser: parser resolveExternalEntityName: nameStr systemID: nil];
	if ( data == nil )
		return ( NULL );
	
	if ( p->myDoc == NULL )
		return ( NULL );
	
	// got a string for the (parsed/resolved) entity, so just hand that in as characters directly
	NSString * str = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
	const char * ch = [str UTF8String];
	__characters( ctx, (const xmlChar *)ch, strlen(ch) );
	[str release];
	
	return ( NULL );
}

static void __startElementNS( void * ctx, const xmlChar *localname, const xmlChar *prefix,
							 const xmlChar *URI, int nb_namespaces, const xmlChar **namespaces,
							 int nb_attributes, int nb_defaulted, const xmlChar **attributes)
{
	AQXMLParser * parser = (AQXMLParser *) ctx;
	id<AQXMLParserDelegate> delegate = [parser delegate];
	
	BOOL processNS = [parser shouldProcessNamespaces];
	BOOL reportNS = [parser shouldReportNamespacePrefixes];
	
	NSString * prefixStr = NSStringFromXmlChar(prefix);
	NSString * localnameStr = NSStringFromXmlChar(localname);
	
	NSString * completeStr = nil;
	if ( [prefixStr length] != 0 )
		completeStr = [[[NSString alloc] initWithFormat: @"%@:%@", prefixStr, localnameStr] autorelease];
	else
		completeStr = [[localnameStr retain] autorelease];
	
	NSString * uriStr = nil;
	if ( processNS )
		uriStr = NSStringFromXmlChar(URI);
	
	NSMutableDictionary * attrDict = [[NSMutableDictionary alloc] initWithCapacity: nb_attributes + nb_namespaces];
	
	NSMutableDictionary * nsDict = nil;
	if ( reportNS )
		nsDict = [[NSMutableDictionary alloc] initWithCapacity: nb_namespaces];
	
	int i;
	for ( i = 0; i < (nb_namespaces * 2); i += 2 )
	{
		NSString * namespaceStr = nil;
		NSString * qualifiedStr = nil;
		
		if ( namespaces[i] == NULL )
		{
			qualifiedStr = @"xmlns";
		}
		else
		{
			namespaceStr = NSStringFromXmlChar(namespaces[i]);
			qualifiedStr = [[NSString alloc] initWithFormat: @"xmlns:%@", namespaceStr];
		}
		
		NSString * val = nil;
		if ( namespaces[i+1] != NULL )
			val = NSStringFromXmlChar(namespaces[i+1]);
		else
			val = @"";
		
		[nsDict setObject: val forKey: completeStr];
		[attrDict setObject: val forKey: qualifiedStr];
		
		[namespaceStr release];
		[qualifiedStr release];
		[val release];
	}
	
	if ( reportNS )
		[parser _pushNamespaces: nsDict];
	[nsDict release];
	
	for ( i = 0; i < (nb_attributes * 5); i += 5 )
	{
		if ( attributes[i] == NULL )
			continue;
		
		NSString * attrLocalName = NSStringFromXmlChar(attributes[i]);
		
		NSString * attrPrefix = nil;
		if ( attributes[i+1] != NULL )
			attrPrefix = NSStringFromXmlChar(attributes[i+1]);
		
		NSString * attrQualified = nil;
		if ( [attrPrefix length] != 0 )
			attrQualified = [[[NSString alloc] initWithFormat: @"%@:%@", attrPrefix, attrLocalName] autorelease];
		else
			attrQualified = [[attrLocalName retain] autorelease];
		
		[attrPrefix release];
		
		NSString * attrValue = @"";
		if ( (attributes[i+3] != NULL) && (attributes[i+4] != NULL) )
		{
			NSUInteger length = attributes[i+4] - attributes[i+3];
			attrValue = [[NSString alloc] initWithBytes: attributes[i+3]
												 length: length
											   encoding: NSUTF8StringEncoding];
		}
		
		[attrDict setObject: attrValue forKey: attrQualified];
		
		[attrQualified release];
		[attrValue release];
	}
	
	if ( [delegate respondsToSelector: @selector(parser:didStartElement:namespaceURI:qualifiedName:attributes:)] )
	{
		[delegate parser: parser
		 didStartElement: localnameStr
			namespaceURI: uriStr
		   qualifiedName: completeStr
			  attributes: attrDict];
	}
	
	[localnameStr release];
	[prefixStr release];
	[uriStr release];
	[completeStr release];
	[attrDict release];
}

#pragma mark -

@implementation AQXMLParser

@synthesize delegate=_delegate;

- (id) initWithStream: (NSInputStream *) stream
{
	if ( [super init] == nil )
		return ( nil );
	
	_internal = [[_AQXMLParserInternal alloc] init];
	_internal->saxHandler = NSAllocateCollectable( sizeof(struct _xmlSAXHandler), 0 );
	_internal->parserContext = NULL;
	_internal->error = nil;
	
	_stream = [stream retain];
	
	[self _initializeSAX2Callbacks];
	
	return ( self );
}

- (void) dealloc
{
	[_internal->error release];
	[_internal->namespaces release];
	NSZoneFree( nil, _internal->saxHandler );
	
	if ( _internal->parserContext != NULL )
	{
		if ( _internal->parserContext->myDoc != NULL )
			xmlFreeDoc( _internal->parserContext->myDoc );
		xmlFreeParserCtxt( _internal->parserContext );
	}
	
	[_internal release];
	[_stream release];
	
	[super dealloc];
}

- (void) finalize
{
	if ( _internal->parserContext != NULL )
	{
		if ( _internal->parserContext->myDoc != NULL )
			xmlFreeDoc( _internal->parserContext->myDoc );
		xmlFreeParserCtxt( _internal->parserContext );
	}
	
	[super finalize];
}

- (BOOL) shouldProcessNamespaces
{
	return ( (_internal->parserFlags & AQXMLParserShouldProcessNamespaces) == AQXMLParserShouldProcessNamespaces );
}

- (void) setShouldProcessNamespaces: (BOOL) value
{
	// don't change if we're already parsing
	if ( [self _parserContext] != NULL )
		return;
	
	if ( value )
		_internal->parserFlags |= AQXMLParserShouldProcessNamespaces;
	else
		_internal->parserFlags &= ~AQXMLParserShouldProcessNamespaces;
}

- (BOOL) shouldReportNamespacePrefixes
{
	return ( (_internal->parserFlags & AQXMLParserShouldReportPrefixes) == AQXMLParserShouldReportPrefixes );
}

- (void) setShouldReportNamespacePrefixes: (BOOL) value
{
	if ( [self _parserContext] != NULL )
		return;
	
	if ( value )
		_internal->parserFlags |= AQXMLParserShouldReportPrefixes;
	else
		_internal->parserFlags &= ~AQXMLParserShouldReportPrefixes;
}

- (BOOL) shouldResolveExternalEntities
{
	return ( (_internal->parserFlags & AQXMLParserShouldResolveExternals) == AQXMLParserShouldResolveExternals );
}

- (void) setShouldResolveExternalEntities: (BOOL) value
{
	if ( [self _parserContext] != NULL )
		return;
	
	if ( value )
		_internal->parserFlags |= AQXMLParserShouldResolveExternals;
	else
		_internal->parserFlags &= ~AQXMLParserShouldResolveExternals;
}

- (BOOL) parse
{
	if ( _stream == nil )
		return ( NO );
	
	xmlSAXHandlerPtr saxHandler = NULL;
	if ( self.delegate != nil )
		saxHandler = _internal->saxHandler;
	
	// see if bytes are already available on the stream
	// if there are, we'll grab the first 4 bytes and use those to compute the encoding
	// otherwise, we'll just go with no initial data
	uint8_t buf[4];
	size_t buflen = 0;
	
	if ( [_stream hasBytesAvailable] )
		buflen = [_stream read: buf maxLength: 4];
	
	_internal->parserContext = xmlCreatePushParserCtxt( saxHandler, self,
													    (const char *)(buflen > 0 ? buf : NULL),
													    buflen, NULL );
	
	int options = [self shouldResolveExternalEntities] ? 
			XML_PARSE_RECOVER | XML_PARSE_NOENT | XML_PARSE_DTDLOAD :
			XML_PARSE_RECOVER | XML_PARSE_DTDATTR;
	
	xmlCtxtUseOptions( _internal->parserContext, options );
	
	_streamComplete = NO;
	
	// start the stream processing going
	[_stream setDelegate: self];
	[_stream scheduleInRunLoop: [NSRunLoop currentRunLoop] forMode: NSRunLoopCommonModes];
	
	if ( [_stream streamStatus] == NSStreamStatusNotOpen )
		[_stream open];
	
	// run in the common runloop modes while we read the data from the stream
	do
	{
		NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
		[[NSRunLoop currentRunLoop] runMode: NSRunLoopCommonModes beforeDate: [NSDate distantFuture]];
		[pool drain];
		
	} while ( _streamComplete == NO );
	
	[_stream setDelegate: nil];
	[_stream removeFromRunLoop: [NSRunLoop currentRunLoop] forMode: NSRunLoopCommonModes];
	[_stream close];
	
	return ( _internal->error == nil );
}

- (void) stream: (NSStream *) stream handleEvent: (NSStreamEvent) streamEvent
{
	NSInputStream * input = (NSInputStream *) stream;
	
	switch ( streamEvent )
	{
		case NSStreamEventOpenCompleted:
		default:
			break;
			
		case NSStreamEventErrorOccurred:
		{
			_internal->error = [input streamError];
			if ( [_delegate respondsToSelector: @selector(parser:parseErrorOccurred:)] )
				[_delegate parser: self parseErrorOccurred: _internal->error];
			_streamComplete = YES;
			break;
		}
			
		case NSStreamEventEndEncountered:
		{
			xmlParseChunk( _internal->parserContext, NULL, 0, 1 );
			_streamComplete = YES;
			break;
		}
			
		case NSStreamEventHasBytesAvailable:
		{
			uint8_t buf[1024];
			int len = [input read: buf maxLength: 1024];
			if ( len > 0 )
			{
				int err = xmlParseChunk( _internal->parserContext, (const char *)buf, len, 0 );
				if ( err != XML_ERR_OK )
				{
					[self _setParserError: err];
					_streamComplete = YES;
				}
			}
			
			break;
		}
	}
}

- (void) abortParsing
{
	if ( _internal->parserContext == NULL )
		return;
	
	_internal->delegateAborted = YES;
	xmlStopParser( _internal->parserContext );
}

- (NSError *) parserError
{
	return ( [[_internal->error retain] autorelease] );
}

@end

@implementation AQXMLParser (AQXMLParserLocatorAdditions)

- (NSString *) publicID
{
	return ( nil );
}

- (NSString *) systemID
{
	return ( nil );
}

- (NSInteger) lineNumber
{
	if ( _internal->parserContext == NULL )
		return ( 0 );
	
	return ( xmlSAX2GetLineNumber(_internal->parserContext) );
}

- (NSInteger) columnNumber
{
	if ( _internal->parserContext == NULL )
		return ( 0 );
	
	return ( xmlSAX2GetColumnNumber(_internal->parserContext) );
}

@end

@implementation AQXMLParser (Internal)

- (void) _setParserError: (int) err
{
	[_internal->error release];
	_internal->error = [[NSError alloc] initWithDomain: NSXMLParserErrorDomain
												  code: err
											  userInfo: nil];
}

- (xmlParserCtxtPtr) _parserContext
{
	return ( _internal->parserContext );
}

- (void) _pushNamespaces: (NSDictionary *) nsDict
{
	if ( _internal->namespaces == nil )
		_internal->namespaces = [[NSMutableArray alloc] init];
	
	if ( nsDict != nil )
	{
		[_internal->namespaces addObject: nsDict];
		
		if ( [_delegate respondsToSelector: @selector(parser:didStartMappingPrefix:toURI:)] )
		{
			for ( NSString * key in nsDict )
			{
				[_delegate parser: self didStartMappingPrefix: key toURI: [nsDict objectForKey: key]];
			}
		}
	}
	else
	{
		[_internal->namespaces addObject: [NSNull null]];
	}
}

- (void) _popNamespaces
{
	id obj = [_internal->namespaces lastObject];
	if ( obj == nil )
		return;
	
	if ( [obj isEqual: [NSNull null]] == NO )
	{
		if ( [_delegate respondsToSelector: @selector(parser:didEndMappingPrefix:)] )
		{
			for ( NSString * key in obj )
			{
				[_delegate parser: self didEndMappingPrefix: key];
			}
		}
	}
	
	[_internal->namespaces removeLastObject];
}

- (void) _initializeSAX2Callbacks
{
	xmlSAXHandlerPtr p = _internal->saxHandler;
	
	p->internalSubset = __internalSubset2;
	p->isStandalone = __isStandalone;
	p->hasInternalSubset = __hasInternalSubset2;
	p->hasExternalSubset = __hasExternalSubset2;
	p->resolveEntity = __resolveEntity;
	p->getEntity = __getEntity;
	p->entityDecl = __entityDecl;
	p->notationDecl = __notationDecl;
	p->attributeDecl = __attributeDecl;
	p->elementDecl = __elementDecl;
	p->unparsedEntityDecl = __unparsedEntityDecl;
	p->setDocumentLocator = NULL;
	p->startDocument = __startDocument;
	p->endDocument = __endDocument;
	p->startElement = NULL;
	p->endElement = NULL;
	p->startElementNs = __startElementNS;
	p->endElementNs = __endElementNS;
	p->reference = NULL;
	p->characters = __characters;
	p->ignorableWhitespace = NULL;
	p->processingInstruction = __processingInstruction;
	p->warning = NULL;
	p->error = __errorCallback;
	xmlSetStructuredErrorFunc( self, __structuredErrorFunc );
	p->getParameterEntity = __getParameterEntity;
	p->cdataBlock = __cdataBlock;
	p->comment = __comment;
	p->externalSubset = __externalSubset2;
	p->initialized = XML_SAX2_MAGIC;
}

- (_AQXMLParserInternal *) _info
{
	return ( _internal );
}

@end

