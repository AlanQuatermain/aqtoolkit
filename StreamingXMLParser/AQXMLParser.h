/*
 *  AQXMLParser.h
 *  AQToolkit
 *
 *  Created by Jim Dovey on 17/3/2009.
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

#import <Foundation/Foundation.h>

@class _AQXMLParserInternal;
@protocol AQXMLParserDelegate;

// delegates should implement the same functions used by AQXMLParser

@interface AQXMLParser : NSObject
{
	void *							_parser;
	id<AQXMLParserDelegate> __weak	_delegate;
	NSInputStream *					_stream;
	_AQXMLParserInternal *			_internal;
	BOOL							_streamComplete;
}

- (id) initWithStream: (NSInputStream *) stream;

@property (assign) id<AQXMLParserDelegate> __weak delegate;

@property (assign) BOOL shouldProcessNamespaces;
@property (assign) BOOL shouldReportNamespacePrefixes;
@property (assign) BOOL shouldResolveExternalEntities;

- (BOOL) parse;
- (void) abortParsing;

@property (readonly) NSError * parserError;

@end

@interface AQXMLParser (AQXMLParserLocatorAdditions)
@property (readonly, retain) NSString * publicID;
@property (readonly, retain) NSString * systemID;
@property (readonly) NSInteger lineNumber;
@property (readonly) NSInteger columnNumber;
@end

// tweaked versions of the delegate functions, accepting AQXMLParser instead of AQXMLParser (gets rid of compiler warnings)

/*
 
 For the discussion of event methods, assume the following XML:
 
 <?xml version="1.0" encoding="UTF-8"?>
 <?xml-stylesheet type='text/css' href='cvslog.css'?>
 <!DOCTYPE cvslog SYSTEM "cvslog.dtd">
 <cvslog xmlns="http://xml.apple.com/cvslog">
 <radar:radar xmlns:radar="http://xml.apple.com/radar">
 <radar:bugID>2920186</radar:bugID>
 <radar:title>API/AQXMLParser: there ought to be an AQXMLParser</radar:title>
 </radar:radar>
 </cvslog>
 
 */

// The parser's delegate is informed of events through the methods in the AQXMLParserDelegate protocol.
@protocol AQXMLParserDelegate <NSObject>
@optional
// Document handling methods
- (void)parserDidStartDocument:(AQXMLParser *)parser;
// sent when the parser begins parsing of the document.
- (void)parserDidEndDocument:(AQXMLParser *)parser;
// sent when the parser has completed parsing. If this is encountered, the parse was successful.

// DTD handling methods for various declarations.
- (void)parser:(AQXMLParser *)parser foundNotationDeclarationWithName:(NSString *)name publicID:(NSString *)publicID systemID:(NSString *)systemID;

- (void)parser:(AQXMLParser *)parser foundUnparsedEntityDeclarationWithName:(NSString *)name publicID:(NSString *)publicID systemID:(NSString *)systemID notationName:(NSString *)notationName;

- (void)parser:(AQXMLParser *)parser foundAttributeDeclarationWithName:(NSString *)attributeName forElement:(NSString *)elementName type:(NSString *)type defaultValue:(NSString *)defaultValue;

- (void)parser:(AQXMLParser *)parser foundElementDeclarationWithName:(NSString *)elementName model:(NSString *)model;

- (void)parser:(AQXMLParser *)parser foundInternalEntityDeclarationWithName:(NSString *)name value:(NSString *)value;

- (void)parser:(AQXMLParser *)parser foundExternalEntityDeclarationWithName:(NSString *)name publicID:(NSString *)publicID systemID:(NSString *)systemID;

- (void)parser:(AQXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict;
// sent when the parser finds an element start tag.
// In the case of the cvslog tag, the following is what the delegate receives:
//   elementName == cvslog, namespaceURI == http://xml.apple.com/cvslog, qualifiedName == cvslog
// In the case of the radar tag, the following is what's passed in:
//    elementName == radar, namespaceURI == http://xml.apple.com/radar, qualifiedName == radar:radar
// If namespace processing >isn't< on, the xmlns:radar="http://xml.apple.com/radar" is returned as an attribute pair, the elementName is 'radar:radar' and there is no qualifiedName.

- (void)parser:(AQXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName;
// sent when an end tag is encountered. The various parameters are supplied as above.

- (void)parser:(AQXMLParser *)parser didStartMappingPrefix:(NSString *)prefix toURI:(NSString *)namespaceURI;
// sent when the parser first sees a namespace attribute.
// In the case of the cvslog tag, before the didStartElement:, you'd get one of these with prefix == @"" and namespaceURI == @"http://xml.apple.com/cvslog" (i.e. the default namespace)
// In the case of the radar:radar tag, before the didStartElement: you'd get one of these with prefix == @"radar" and namespaceURI == @"http://xml.apple.com/radar"

- (void)parser:(AQXMLParser *)parser didEndMappingPrefix:(NSString *)prefix;
// sent when the namespace prefix in question goes out of scope.

- (void)parser:(AQXMLParser *)parser foundCharacters:(NSString *)string;
// This returns the string of the characters encountered thus far. You may not necessarily get the longest character run. The parser reserves the right to hand these to the delegate as potentially many calls in a row to -parser:foundCharacters:

- (void)parser:(AQXMLParser *)parser foundIgnorableWhitespace:(NSString *)whitespaceString;
// The parser reports ignorable whitespace in the same way as characters it's found.

- (void)parser:(AQXMLParser *)parser foundProcessingInstructionWithTarget:(NSString *)target data:(NSString *)data;
// The parser reports a processing instruction to you using this method. In the case above, target == @"xml-stylesheet" and data == @"type='text/css' href='cvslog.css'"

- (void)parser:(AQXMLParser *)parser foundComment:(NSString *)comment;
// A comment (Text in a <!-- --> block) is reported to the delegate as a single string

- (void)parser:(AQXMLParser *)parser foundCDATA:(NSData *)CDATABlock;
// this reports a CDATA block to the delegate as an NSData.

- (NSData *)parser:(AQXMLParser *)parser resolveExternalEntityName:(NSString *)name systemID:(NSString *)systemID;
// this gives the delegate an opportunity to resolve an external entity itself and reply with the resulting data.

- (void)parser:(AQXMLParser *)parser parseErrorOccurred:(NSError *)parseError;
// ...and this reports a fatal error to the delegate. The parser will stop parsing.

- (void)parser:(AQXMLParser *)parser validationErrorOccurred:(NSError *)validationError;
// If validation is on, this will report a fatal validation error to the delegate. The parser will stop parsing.
@end
