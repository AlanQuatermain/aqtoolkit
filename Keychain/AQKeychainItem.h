/*
 * AQKeychainItem.h
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


#import <Foundation/Foundation.h>
#import <Security/SecItem.h>

// Supported classes:
//  - kSecClassGenericPassword
//  - kSecClassInternetPassword

/*
 
 These are the default constants and their respective types,
 available for the kSecClassGenericPassword Keychain Item class:
 
 kSecAttrAccessGroup		-		CFStringRef
 kSecAttrCreationDate       -       CFDateRef
 kSecAttrModificationDate   -       CFDateRef
 kSecAttrDescription        -       CFStringRef
 kSecAttrComment            -       CFStringRef
 kSecAttrCreator            -       CFNumberRef (OSType)
 kSecAttrType               -       CFNumberRef (OSType)
 kSecAttrLabel              -       CFStringRef
 kSecAttrIsInvisible        -       CFBooleanRef
 kSecAttrIsNegative         -       CFBooleanRef
 kSecAttrAccount            -       CFStringRef		-- username value
 kSecAttrService            -       CFStringRef		-- server URL string
 kSecAttrGeneric            -       CFDataRef
 
 ...and these are for the kSecClassInternetPassword class:
 
 kSecAttrAccessGroup		-		CFStringRef		-- iPhone only
 kSecAttrCreationDate		-		CFDateRef
 kSecAttrModificationDate	-		CFDateRef
 kSecAttrDescription		-		CFStringRef
 kSecAttrComment			-		CFStringRef
 kSecAttrCreator			-		CFNumberRef (OSType)
 kSecAttrType				-		CFNumberRef (OSType)
 kSecAttrLabel				-		CFStringRef
 kSecAttrIsInvisible		-		CFBooleanRef
 kSecAttrIsNegative			-		CFBooleanRef
 kSecAttrAccount			-		CFStringRef		-- username value
 kSecAttrSecurityDomain		-		CFStringRef		-- use server URL host string
 kSecAttrServer				-		CFStringRef		-- server URL host string
 kSecAttrProtocol			-		CFTypeRef		-- kSecAttrProtocolXXXXX
 kSecAttrAuthenticationType	-		CFTypeRef		-- kSecAttrAuthenticationTypeXXXXX
 kSecAttrPort				-		CFNumberRef		-- port number
 kSecAttrPath				-		CFStringRef		-- path component of URL (leave empty for all)
 
 ... and don't forget -- even though the docs don't mention this, you have to SET
 kSecValueData to be the encrypted value (the password) that you want to store.
 
*/

// options to specify the type of data to return
enum
{
    kAQKeychainReturnNone           = 0,
    kAQKeychainReturnAttributes     = 1 << 0,
    kAQKeychainReturnData           = 1 << 1,
    kAQKeychainReturnRef            = 1 << 2,
    kAQKeychainReturnPersistentRef  = 1 << 3,
    
    kAQKeychainReturnAll            = 0xFFFFFFFF
    
};
typedef NSUInteger AQKeychainOptions;

@interface AQKeychainItem : NSObject <NSCoding>
{
	NSMutableDictionary *	_keychainData;
}

@property (nonatomic, retain) NSMutableDictionary * keychainData;

// primitives
- (void) setObject: (id) object forKey: (id) key;
- (id) objectForKey: (id) key;

// helpers (which sit atop -setObject:forKey: and objectForKey:)
// note that those things which are provided as CFTypeRef constants are declared as such here
@property (nonatomic)		  CFTypeRef itemClass;
#if TARGET_OS_IPHONE
@property (nonatomic, retain) NSString * group;
#endif
@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain, getter=itemDescription, setter=setItemDescription:) NSString * description;
@property (nonatomic, retain) NSString * comment;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSString * password;
@property (nonatomic, retain) NSString * securityDomain;
@property (nonatomic, retain) NSString * server;
#if TARGET_OS_IPHONE
@property (nonatomic)		  CFTypeRef protocol;		// on iPhone, uses CFTypeRef extern constants
#else
@property (nonatomic, assign) FourCharCode protocol;	// on Mac, uses enumerated OSType constants
#endif
@property (nonatomic)		  CFTypeRef authenticationType;
@property (nonatomic)		  UInt16 port;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSData * generic;

@property (nonatomic, copy) NSData * valueData;
@property (nonatomic, readonly) CFTypeRef keychainItemRef;

// clear the protected value when you're done with it
- (void) clearValueData;

// these functions will actually fetch/store the item

// This will update the keychainData dictionary using the returned data
- (BOOL) queryKeychain;
- (BOOL) queryKeychainWithOptions: (AQKeychainOptions) options;

// This will create or update the keychain item
- (BOOL) storeKeychain;

// This will delete the matching keychain item
- (BOOL) deleteKeychain;

+ (NSArray *) findMatchingItems: (AQKeychainItem *) query;
+ (NSArray *) findMatchingItems: (AQKeychainItem *) query withOptions: (AQKeychainOptions) options;

@end
