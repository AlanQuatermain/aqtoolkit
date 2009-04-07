/*
 *  AQXMLParserDelegate.m
 *  AQToolkit
 *
 *  Created by Jim Dovey on 23/01/09.
 *  
 *  Copyright (c) 2009 Jim Dovey.
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

#import "AQXMLParserDelegate.h"
#import "AQXMLParser.h"

@interface AQXMLParserDelegate (ParserMagic)

- (SEL) _startSelectorForElement: (NSString *) elementName;
- (SEL) _endSelectorForElement: (NSString *) elementName;

@end

@implementation AQXMLParserDelegate

@synthesize characters=_characters;

- (void) dealloc
{
	[_characters release];
	[super dealloc];
}

- (void) parser: (AQXMLParser *) parser didStartElement: (NSString *) elementName
   namespaceURI: (NSString *) namespaceURI qualifiedName: (NSString *) qName
     attributes: (NSDictionary *) attributeDict
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	SEL selector = [self _startSelectorForElement: elementName];
	
    if ( [self respondsToSelector: selector] )
    {
        //NSLog( @"Parser: calling -%@", NSStringFromSelector(selector) );
        [self performSelector: selector withObject: attributeDict];
    }
	
    self.characters = nil;
	
	[pool drain];
}

- (void) parser: (AQXMLParser *) parser didEndElement: (NSString *) elementName
   namespaceURI: (NSString *) namespaceURI qualifiedName: (NSString *) qName
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	SEL selector = [self _endSelectorForElement: elementName];
	
    if ( [self respondsToSelector: selector] )
    {
        //NSLog( @"Parser: calling -%@", NSStringFromSelector(selector) );
        [self performSelector: selector];
    }
	
	self.characters = nil;
	
	[pool drain];
}

- (void) parser: (AQXMLParser *) parser foundCDATA: (NSData *) CDATABlock
{
	NSString * chars = [[NSString alloc] initWithData: CDATABlock encoding: NSUTF8StringEncoding];
    [self parser: parser foundCharacters: chars];
    [chars release];
}

- (void) parser: (AQXMLParser *) parser foundCharacters: (NSString *) string
{
	if ( string == nil )
        return;
	
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
	if ( self.characters != nil )
    {
        self.characters = [self.characters stringByAppendingString: string];
    }
    else
    {
        self.characters = string;
    }
	
	[pool drain];
}

- (void) parser: (AQXMLParser *) parser parseErrorOccurred: (NSError *) error
{
	// superclass does nothing
}

@end

@implementation AQXMLParserDelegate (ParserMagic)

- (SEL) _startSelectorForElement: (NSString *) element
{
    NSString * str = nil;
    NSMutableString * eSel = [NSMutableString stringWithString: [[element substringWithRange: NSMakeRange(0,1)] uppercaseString]];
	
    if ( [element length] > 1 )
	{
        [eSel appendString: [element substringFromIndex: 1]];
		
		NSRange range = [eSel rangeOfString: @"-"];
		for ( ; range.location != NSNotFound; range = [eSel rangeOfString: @"-"] )
		{
			NSString * cap = [[eSel substringWithRange: NSMakeRange(range.location+1, 1)] uppercaseString];
			range.length += 1;
			[eSel replaceCharactersInRange: range withString: cap];
		}
	}
	
	str = [NSString stringWithFormat: @"start%@WithAttributes:", eSel];
	
    return ( NSSelectorFromString(str) );
}

- (SEL) _endSelectorForElement: (NSString *) element
{
    NSString * str = nil;
    NSMutableString * eSel = [NSMutableString stringWithString: [[element substringWithRange: NSMakeRange(0,1)] uppercaseString]];
	
    if ( [element length] > 1 )
	{
        [eSel appendString: [element substringFromIndex: 1]];
		
		NSRange range = [eSel rangeOfString: @"-"];
		for ( ; range.location != NSNotFound; range = [eSel rangeOfString: @"-"] )
		{
			NSString * cap = [[eSel substringWithRange: NSMakeRange(range.location+1, 1)] uppercaseString];
			range.length += 1;
			[eSel replaceCharactersInRange: range withString: cap];
		}
	}
	
	str = [NSString stringWithFormat: @"end%@", eSel];
	
    return ( NSSelectorFromString(str) );
}

@end
