/*
 *  AQXMLObjectReader.m
 *  XML Object Parser
 *
 *  Created by Jim Dovey on 7/7/2008.
 *  Copyright (c) 2008 Jim Dovey. Some Rights Reserved.
 *
 *  This work is licensed under a Creative Commons
 *  Attribution-Noncommercial-Share Alike License. You are
 *  free to use and redistribute this work, but may not use
 *  it for commercial purposes, and any changes you make
 *  must be released under the same or similar license.
 *  In addition, you must include the following disclaimer:
 *
 *    Portions Copyright (c) 2008 Jim Dovey
 *
 *  For license details, see:
 *    http://creativecommons.org/licenses/by-nc-sa/3.0/
 *
 */

#import "AQXMLObjectReader.h"
#import "AQXMLObjectParseHandler.h"
#import "NSObject+Properties.h"

@interface AQXMLObjectReader (ImplementationDetails)

// recursive parser routine
- (BOOL) parseElement: (NSXMLElement *) element;

// element/attribute name -> property name munging
- (NSString *) propertyNameForElementName: (NSString *) tag;

// check whether a class has a conformant property
- (BOOL) class: (Class) cls hasPropertyNamed: (NSString *) name ofType: (const char *) type;
// get the property type from a class's property (if available)
- (BOOL) class: (Class) cls hasPropertyNamed: (NSString *) name getType: (const char **) type;

@end

@implementation AQXMLObjectReader

@synthesize parsedObject=_parsedObject;

+ (id) parseXMLDocument: (NSXMLDocument *) document 
	 usingClassProvider: (id<AQXMLObjectClassProvider>) classProvider
{
	AQXMLObjectReader * tempReader = [[self alloc] initWithProvider: classProvider];
	if ( tempReader == nil )
		return ( nil );
	
	id result = [tempReader parseXMLDocument: document];
	[tempReader release];
	
	return ( result );
}

- (id) initWithProvider: (id<AQXMLObjectClassProvider>) provider
{
	if ( [super init] == nil )
		return ( nil );
	
	if ( [provider conformsToProtocol: @protocol(AQXMLObjectClassProvider)] == NO )
	{
		[self release];
		return ( nil );
	}
	
	_classProvider = provider;
	_objectStack = [NSMutableArray new];
	
	return ( self );
}

- (void) dealloc
{
	[_objectStack release];
	[_parsedObject release];
	[super dealloc];
}

- (id) parseXMLDocument: (NSXMLDocument *) document
{
	@synchronized(self)
	{
		[_parsedObject release];
		_parsedObject = nil;
	}
	
	(void) [self parseElement: [document rootElement]];
	
	return ( [[self.parsedObject retain] autorelease] );
}

@end

@implementation AQXMLObjectReader (ImplementationDetails)

- (BOOL) parseElement: (NSXMLElement *) element
{
	id object = [_objectStack lastObject];

	Class cls = [_classProvider classForTagName: [element name]];
	if ( cls != nil )
	{
		// create an instance of this class and push it onto the stack
		// note that this doesn't (yet) include any support for uniquing,
		// since that would be a fair bit more fiddly to actually put together
		// (at least for the moment)
		
		// check whether the parent (if it exists) has a matching property
		if ( object != nil )
		{
			NSString * propName = [self propertyNameForElementName: [element name]];
			if ( [object hasPropertyNamed: propName] )
			{
				
			}
		}
		
		object = [[cls alloc] init];
		[_objectStack addObject: object];
		[object release];
	}
	
	if ( object == nil )
	{
		// nowhere to put this, so skip it
		return ( NO );
	}
}

- (NSString *) propertyNameForElementName: (NSString *) elementName
{
	// split string on hyphens and/or underscores
	NSArray * components = [elementName componentsSeparatedByCharactersInSet: [[NSCharacterSet alphanumericCharacterSet] invertedSet]];
	NSMutableString * str = [NSMutableString stringWithString: [components objectAtIndex: 0]];
	
	for ( NSString * component in [components subarrayWithRange: NSMakeRange(1, [components count] -1)] )
	{
		NSString * tmp = = [[component substringWithRange: NSMakeRange(0,1)] uppercaseString];
		if ( [component length] > 0 )
			tmp = [tmp stringByAppendingString: [component substringFromIndex: 1]];
		
		[str appendString: tmp];
	}
	
	// we now have a camelCaseString version of the element name
	// there are a couple of important changes we need to make, however:
	static NSDictionary * __replacements = nil;
	if ( __replacements == nil )
	{
		__replacements = [[NSDictionary alloc] initWithObjectsAndKeys: @"ID", @"id",
						  @"itemDescription", @"description", nil];
	}
	
	// return a replacement if necessary
	NSString * replace = [__replacements objectForKey: str];
	if ( replace != nil )
		return ( replace );
	
	// otherwise return an immutable copy of the camelCaseString
	return ( [[str copy] autorelease] );
}

@end
