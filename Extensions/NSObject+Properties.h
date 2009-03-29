/*
 *  NSObject+Properties.h
 *  AQToolkit
 *
 *  Created by Jim Dovey on 10/7/2008.
 *
 *  Copyright (c) 2008-2009, Jim Dovey
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

#import <Foundation/NSObject.h>
#import <objc/runtime.h>

// type notes:
// I'm not 100% certain what @encode(NSString) would return. @encode(id) returns '@', 
// and the types of properties are actually encoded as such along with a strong-type
// value following. Therefore, if you want to check for a specific class, you can 
// provide a type string of '@"NSString"'. The following macro will do this for you.
#define statictype(x)	"@\"" #x "\""

// Also, note that the runtime information doesn't include an atomicity hint, so we
// can't determine that information

@interface NSObject (AQProperties)

+ (BOOL) hasProperties;
+ (BOOL) hasPropertyNamed: (NSString *) name;
+ (BOOL) hasPropertyNamed: (NSString *) name ofType: (const char *) type;	// an @encode() or statictype() type string
+ (BOOL) hasPropertyForKVCKey: (NSString *) key;
+ (const char *) typeOfPropertyNamed: (NSString *) name;	// returns an @encode() or statictype() string. Copy to keep
+ (SEL) getterForPropertyNamed: (NSString *) name;
+ (SEL) setterForPropertyNamed: (NSString *) name;
+ (NSString *) retentionMethodOfPropertyNamed: (NSString *) name;		// returns one of: copy, retain, assign
+ (NSArray *) propertyNames;

// instance convenience accessors for above routines (who likes to type [myObj class] all the time ?)
- (BOOL) hasProperties;
- (BOOL) hasPropertyNamed: (NSString *) name;
- (BOOL) hasPropertyNamed: (NSString *) name ofType: (const char *) type;
- (BOOL) hasPropertyForKVCKey: (NSString *) key;
- (const char *) typeOfPropertyNamed: (NSString *) name;
- (SEL) getterForPropertyNamed: (NSString *) name;
- (SEL) setterForPropertyNamed: (NSString *) name;
- (NSString *) retentionMethodOfPropertyNamed: (NSString *) name;
- (NSArray *) propertyNames;

@end

// Pure C API, adding to the existing API in objc/runtime.h.
// The functions above are implemented in terms of these.

// returns a static buffer - copy the string to retain it, as it will
// be overwritten on the next call to this function
const char * property_getTypeString( objc_property_t property );

// getter/setter functions: unlike those above, these will return NULL unless a getter/setter is EXPLICITLY defined
SEL property_getGetter( objc_property_t property );
SEL property_getSetter( objc_property_t property );

// this returns a static (data-segment) string, so the caller does not need to call free() on the result
const char * property_getRetentionMethod( objc_property_t property );
