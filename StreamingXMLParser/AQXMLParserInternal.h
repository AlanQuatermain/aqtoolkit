//
//  AQXMLParserInternal.h
//  Kobov3
//
//  Created by Jim Dovey on 10-04-08.
//  Copyright 2010 Kobo Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <libxml/parser.h>
#import <libxml/HTMLparser.h>
#import <libxml/parserInternals.h>
#import <libxml/SAX2.h>
#import <libxml/xmlerror.h>
#import <libxml/encoding.h>
#import <libxml/entities.h>

@interface _AQXMLParserInternal : NSObject
{
@public
    // parser structures -- these are actually the same for both XML & HTML
	xmlSAXHandlerPtr	saxHandler;
	xmlParserCtxtPtr	parserContext;
	
    // internal stuff
    NSUInteger			parserFlags;
	NSError *			error;
	NSMutableArray *	namespaces;
	BOOL				delegateAborted;
    
    // async parse callback data
    id                  asyncDelegate;
    SEL                 asyncSelector;
    void *              asyncContext;
    
    // progress variables
    float               expectedDataLength;
    float               currentLength;
	
	NSOutputStream *	debugOutputStream;
	
	NSRunLoop * __weak	waitingRunLoop;
    
}
@property (nonatomic, readonly) xmlSAXHandlerPtr xmlSaxHandler;
@property (nonatomic, readonly) xmlParserCtxtPtr xmlParserContext;
@property (nonatomic, readonly) htmlSAXHandlerPtr htmlSaxHandler;
@property (nonatomic, readonly) htmlParserCtxtPtr htmlParserContext;
@end
