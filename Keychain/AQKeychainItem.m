/*
 * AQKeychainItem.m
 * AQToolkit
 * 
 * Created by Jim Dovey on 27/03/2009.
 * 
 * Copyright (c) 2009 Jim Dovey
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 
 * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * 
 * Neither the name of the project's author nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#import "AQKeychainItem.h"
#import <Security/Security.h>

@implementation AQKeychainItem

@synthesize keychainData=_keychainData;

- (id) init
{
	if ( [super init] == nil )
		return ( nil );
	
	_keychainData = [[NSMutableDictionary alloc] init];
	
	return ( self );
}

- (id) initWithCoder: (NSCoder *) coder
{
    if ( [super init] == nil )
        return ( nil );
    
    if ( [coder allowsKeyedCoding] )
    {
        _keychainData = [[coder decodeObjectForKey: @"keychainData"] mutableCopy];
    }
    else
    {
        _keychainData = [[coder decodeObject] mutableCopy];
    }
    
    return ( self );
}

- (void) encodeWithCoder: (NSCoder *) coder
{
    if ( [coder allowsKeyedCoding] )
    {
        [coder encodeObject: _keychainData forKey: @"keychainData"];
    }
    else
    {
        [coder encodeObject: _keychainData];
    }
}

- (void) dealloc
{
	[_keychainData release];
	[super dealloc];
}

- (void) setObject: (id) object forKey: (id) key
{
	if ( object == nil )
	{
		[_keychainData removeObjectForKey: key];
		return;
	}
	
	[_keychainData setObject: object forKey: key];
}

- (id) objectForKey: (id) key
{
	return ( [_keychainData objectForKey: key] );
}

- (void) clearValueData
{
	[_keychainData removeObjectForKey: (id)kSecValueData];
    [_keychainData removeObjectForKey: (id)kSecValueRef];
    [_keychainData removeObjectForKey: (id)kSecValuePersistentRef];
}

// RETURNS AN OBJECT WITH A REFCOUNT OF ONE
- (NSMutableDictionary *) copyQueryDictionary: (AQKeychainOptions) options
{
	NSMutableDictionary * query = [[NSMutableDictionary alloc] init];
	
	if ( [_keychainData objectForKey: (id)kSecClass] == nil )
		[query setObject: (id)kSecClassInternetPassword forKey: (id)kSecClass];
	else
		[query setObject: [_keychainData objectForKey: (id)kSecClass] forKey: (id)kSecClass];
	
    if ( options != kAQKeychainReturnNone )
        [query setObject: (id)kSecMatchLimitOne forKey: (id)kSecMatchLimit];
    if ( (options & kAQKeychainReturnAttributes) == kAQKeychainReturnAttributes )
        [query setObject: (id)kCFBooleanTrue forKey: (id)kSecReturnAttributes];
    if ( (options & kAQKeychainReturnData) == kAQKeychainReturnData )
        [query setObject: (id)kCFBooleanTrue forKey: (id)kSecReturnData];
    if ( (options & kAQKeychainReturnRef) == kAQKeychainReturnRef )
        [query setObject: (id)kCFBooleanTrue forKey: (id)kSecReturnRef];
    if ( (options & kAQKeychainReturnPersistentRef) == kAQKeychainReturnPersistentRef )
        [query setObject: (id)kCFBooleanTrue forKey: (id)kSecReturnPersistentRef];
	
	static NSSet * __copySet = nil;
	if ( __copySet == nil )
	{
		__copySet = [[NSSet alloc] initWithObjects: (id)kSecAttrAuthenticationType,
#if TARGET_OS_IPHONE
					 (id)kSecAttrAccessGroup,
#endif
					 (id)kSecAttrAccount, (id)kSecAttrSecurityDomain, (id)kSecAttrPort, (id)kSecAttrPath,
					 (id)kSecAttrGeneric, (id)kSecAttrLabel, (id)kSecAttrDescription, (id)kSecAttrService, (id)kSecAttrApplicationTag, (id)kSecAttrKeyClass, nil];
	}
	
	for ( id key in _keychainData )
	{
		if ( [__copySet containsObject: key] == NO )
			continue;
		
		[query setObject: [_keychainData objectForKey: key]
                  forKey: key];
	}
	
	return ( query );
}

- (BOOL) queryKeychain
{
    return ( [self queryKeychainWithOptions: kAQKeychainReturnAttributes|kAQKeychainReturnData] );
}

- (BOOL) queryKeychainWithOptions: (AQKeychainOptions) options
{
	BOOL result = NO;
	
	NSDictionary * query = [self copyQueryDictionary: options];
	NSDictionary * output = nil;
	
	if ( SecItemCopyMatching((CFDictionaryRef)query, (CFTypeRef *)&output) == noErr )
	{
		result = YES;
		[_keychainData setDictionary: output];
		
		// make sure we keep hold of class/generic
		[_keychainData setObject: [query objectForKey: (id)kSecClass]
						  forKey: (id)kSecClass];
		if ( [query objectForKey: (id)kSecAttrGeneric] != nil )
		{
			[_keychainData setObject: [query objectForKey: (id)kSecAttrGeneric]
							  forKey: (id)kSecAttrGeneric];
		}
	}
	
	[output release];
	[query release];
	
	return ( result );
}

- (BOOL) storeKeychain
{
	NSDictionary * query = [self copyQueryDictionary: kAQKeychainReturnAttributes];
	NSDictionary * output = nil;
	OSStatus err = noErr;
	
	if ( SecItemCopyMatching((CFDictionaryRef)query, (CFTypeRef *)&output) == noErr )
	{
		// there's an existing item to update
		NSMutableDictionary * update = [output mutableCopy];
		
		// ensure we set the class attribute and (maybe) generic tag
		[update setObject: [query objectForKey: (id)kSecClass]
				   forKey: (id)kSecClass];
        
        if ( [query objectForKey: (id)kSecAttrGeneric] != nil )
        {
            [update setObject: [query objectForKey: (id)kSecAttrGeneric]
                       forKey: (id)kSecAttrGeneric];
        }
		
		//NSMutableDictionary * attrs = [update mutableCopy];
		//[attrs removeObjectForKey: (id)kSecClass];
        NSDictionary * attrs = [[NSDictionary alloc] initWithObjectsAndKeys: [_keychainData objectForKey: (id)kSecValueData], (id)kSecValueData, nil];
		
		// save
		err = SecItemUpdate( (CFDictionaryRef)update, (CFDictionaryRef) attrs );
		
		[attrs release];
		[update release];
		[output release];
		
		NSAssert( err == noErr, @"Couldn't update the keychain item." );
	}
	else
	{
		if ( [_keychainData objectForKey: (id)kSecClass] == nil )
			[_keychainData setObject: (id)kSecClassInternetPassword forKey: (id)kSecClass];
		
		err = SecItemAdd( (CFDictionaryRef)_keychainData, NULL );
		NSAssert( err == noErr, @"Couldn't add the keychain item." );
	}
    
    [query release];
	
	return ( err == noErr );
}

- (BOOL) deleteKeychain
{
	BOOL result = NO;
    NSDictionary * query = [self copyQueryDictionary: kAQKeychainReturnNone];   // don't return anything-- deleting
    
	OSStatus err = SecItemDelete( (CFDictionaryRef)query );
    if ( err == noErr )
		result = YES;
	
    [query release];
	return ( result );
}

+ (NSArray *) findMatchingItems: (AQKeychainItem *) query
{
    return ( [self findMatchingItems: query withOptions: kAQKeychainReturnAll] );
}

+ (NSArray *) findMatchingItems: (AQKeychainItem *) item withOptions: (AQKeychainOptions) options
{
	NSMutableDictionary * query = [item copyQueryDictionary: options];
	[query setObject: (id)kSecMatchLimitAll forKey: (id)kSecMatchLimit];
	
	NSArray * results = nil;
	OSStatus err = SecItemCopyMatching( (CFDictionaryRef)query, (CFTypeRef *)&results );
	[query release];
	
	if ( err != noErr )
		return ( nil );
	
	NSMutableArray * output = [NSMutableArray arrayWithCapacity: [results count]];
	for ( NSDictionary * dict in results )
	{
		AQKeychainItem * item = [[AQKeychainItem alloc] init];
        
        NSMutableDictionary * mutable = [dict mutableCopy];
		item.keychainData = mutable;
        [mutable release];
		
        [output addObject: item];
		[item release];
	}
	
	return ( output );
}

#pragma mark -

- (CFTypeRef) itemClass
{
	return ( (CFTypeRef) [_keychainData objectForKey: (id)kSecClass] );
}

- (void) setItemClass: (CFTypeRef) itemClass
{
	[self setObject: (id)itemClass forKey: (id)kSecClass];
}
#if TARGET_OS_IPHONE
- (NSString *) group
{
	return ( (NSString *) [_keychainData objectForKey: (id)kSecAttrAccessGroup] );
}

- (void) setGroup: (NSString *) group
{
	[self setObject: group forKey: (id)kSecAttrAccessGroup];
}
#endif
- (NSString *) label
{
	return ( [_keychainData objectForKey: (id)kSecAttrLabel] );
}

- (void) setLabel: (NSString *) label
{
	[self setObject: label forKey: (id)kSecAttrLabel];
}

- (NSString *) itemDescription
{
	return ( [_keychainData objectForKey: (id)kSecAttrDescription] );
}

- (void) setItemDescription: (NSString *) description
{
	[self setObject: description forKey: (id)kSecAttrDescription];
}

- (NSString *) comment
{
	return ( [_keychainData objectForKey: (id)kSecAttrComment] );
}

- (void) setComment: (NSString *) comment
{
	[self setObject: comment forKey: (id)kSecAttrComment];
}

- (NSString *) username
{
	return ( [_keychainData objectForKey: (id)kSecAttrAccount] );
}

- (void) setUsername: (NSString *) username
{
	[self setObject: username forKey: (id)kSecAttrAccount];
}

- (NSString *) password
{
	NSData * data = self.valueData;
	if ( data == nil )
		return ( nil );
	
	return ( [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease] );
}

- (void) setPassword: (NSString *) password
{
    self.valueData = [password dataUsingEncoding: NSUTF8StringEncoding];
}

- (NSString *) securityDomain
{
	return ( [_keychainData objectForKey: (id)kSecAttrSecurityDomain] );
}

- (void) setSecurityDomain: (NSString *) securityDomain
{
	[self setObject: securityDomain forKey: (id)kSecAttrSecurityDomain];
}

- (NSString *) server
{
	return ( [_keychainData objectForKey: (id)kSecAttrServer] );
}

- (void) setServer: (NSString *) server
{
	[self setObject: server forKey: (id)kSecAttrServer];
}
#if TARGET_OS_IPHONE
- (CFTypeRef) protocol
{
	return ( (CFTypeRef)[_keychainData objectForKey: (id)kSecAttrProtocol] );
}

- (void) setProtocol: (CFTypeRef) protocol
{
	[self setObject: (id)protocol forKey: (id)kSecAttrProtocol];
}
#else
- (FourCharCode) protocol
{
	return ( [[_keychainData objectForKey: (id)kSecAttrProtocol] unsignedIntValue] );
}

- (void) setProtocol: (FourCharCode) protocol
{
	[self setObject: [NSNumber numberWithUnsignedInt: protocol]
			 forKey: (id)kSecAttrProtocol];
}
#endif
- (CFTypeRef) authenticationType
{
	return ( [_keychainData objectForKey: (id)kSecAttrAuthenticationType] );
}

- (void) setAuthenticationType: (CFTypeRef) authenticationType
{
	[self setObject: (id)authenticationType forKey: (id)kSecAttrAuthenticationType];
}

- (UInt16) port
{
	NSNumber * num = [_keychainData objectForKey: (id)kSecAttrPort];
	return ( [num unsignedShortValue] );
}

- (void) setPort: (UInt16) port
{
	NSNumber * num = [[NSNumber alloc] initWithUnsignedShort: port];
	[self setObject: num forKey: (id)kSecAttrPort];
	[num release];
}

- (NSString *) path
{
	return ( [_keychainData objectForKey: (id)kSecAttrPath] );
}

- (void) setPath: (NSString *) path
{
	[self setObject: path forKey: (id)kSecAttrPath];
}

- (NSData *) generic
{
	return ( [_keychainData objectForKey: (id)kSecAttrGeneric] );
}

- (void) setGeneric: (NSData *) data
{
	[self setObject: data forKey: (id)kSecAttrGeneric];
}

- (NSData *) valueData
{
    return ( [_keychainData objectForKey: (id)kSecValueData] );
}

- (void) setValueData: (NSData *) valueData
{
    [self setObject: valueData forKey: (id)kSecValueData];
}

- (CFTypeRef) keychainItemRef
{
    CFTypeRef result = (CFTypeRef)[_keychainData objectForKey: (id)kSecValueRef];
    if ( result != NULL )
        return ( [[(id)result retain] autorelease] );
    
    NSMutableDictionary * query = [self copyQueryDictionary: kAQKeychainReturnRef];
    
    OSStatus err = SecItemCopyMatching( (CFDictionaryRef)query, &result );
    NSAssert( err == noErr, @"Failed to get a SecKeychainItemRef" );
    
    [query release];
    
    if ( result != nil )
        [_keychainData setObject: (id)result forKey: (id)kSecValueRef];
    
    return ( [[(id)result retain] autorelease] );
}

@end
