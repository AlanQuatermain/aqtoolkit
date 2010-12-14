//
//  AQXMLParserInternal.m
//  Kobov3
//
//  Created by Jim Dovey on 10-04-08.
//  Copyright 2010 Kobo Inc. All rights reserved.
//

#import "AQXMLParserInternal.h"

@implementation _AQXMLParserInternal

- (xmlSAXHandlerPtr) xmlSaxHandler
{
    return ( saxHandler );
}

- (xmlParserCtxtPtr) xmlParserContext
{
    return ( parserContext );
}

- (htmlSAXHandlerPtr) htmlSaxHandler
{
    return ( (htmlSAXHandlerPtr) saxHandler );
}

- (htmlParserCtxtPtr) htmlParserContext
{
    return ( (htmlParserCtxtPtr) parserContext );
}

@end