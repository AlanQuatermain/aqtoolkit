/*
 * ABMultiValue.m
 * AQToolkit
 * 
 * Created by Jim Dovey on 6/6/2009.
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

#import "ABMultiValue.h"

@implementation ABMultiValue

@synthesize multiValueRef=_ref;

- (id) initWithABRef: (CFTypeRef) ref
{
    if ( ref == NULL )
    {
        [self release];
        return ( nil );
    }
    
    if ( [super init] == nil )
        return ( nil );
    
    _ref = (ABMultiValueRef) CFRetain(ref);
    
    return ( self );
}

- (void) dealloc
{
    if ( _ref != NULL )
        CFRelease( _ref );
    [super dealloc];
}

- (id) mutableCopyWithZone: (NSZone *) zone
{
    return ( [[ABMutableMultiValue allocWithZone: zone] initWithABRef: (CFTypeRef)ABMultiValueCreateMutableCopy(_ref)] );
}

- (ABPropertyType) propertyType
{
    return ( ABMultiValueGetPropertyType(_ref) );
}

- (NSUInteger) count
{
    return ( (NSUInteger) ABMultiValueGetCount(_ref) );
}

- (id) valueAtIndex: (NSUInteger) index
{
    id value = (id) ABMultiValueCopyValueAtIndex( _ref, (CFIndex)index );
    return ( [value autorelease] );
}

- (NSArray *) allValues
{
    NSArray * array = (NSArray *) ABMultiValueCopyArrayOfAllValues( _ref );
    return ( [array autorelease] );
}

- (NSString *) labelAtIndex: (NSUInteger) index
{
    NSString * result = (NSString *) ABMultiValueCopyLabelAtIndex( _ref, (CFIndex)index );
    return ( [result autorelease] );
}

- (NSUInteger) indexForIdentifier: (ABMultiValueIdentifier) identifier
{
    return ( (NSUInteger) ABMultiValueGetIndexForIdentifier(_ref, identifier) );
}

- (ABMultiValueIdentifier) identifierAtIndex: (NSUInteger) index
{
    return ( ABMultiValueGetIdentifierAtIndex(_ref, (CFIndex)index) );
}

- (NSUInteger) indexOfValue: (id) value
{
    return ( (NSUInteger) ABMultiValueGetFirstIndexOfValue(_ref, (CFTypeRef)value) );
}

@end

#pragma mark -

@implementation ABMutableMultiValue

- (id) initWithPropertyType: (ABPropertyType) type
{
    ABMutableMultiValueRef ref = ABMultiValueCreateMutable(type);
    if ( ref == NULL )
    {
        [self release];
        return ( nil );
    }
    
    return ( [self initWithABRef: (CFTypeRef)ref] );
}

- (id) copyWithZone: (NSZone *) zone
{
    // no AB method to create an immutable copy, so we do a mutable copy but wrap it in an immutable class
    CFTypeRef _obj = ABMultiValueCreateMutableCopy(_ref);
    return ( [[ABMultiValue allocWithZone: zone] initWithABRef: _obj] );
}

- (ABMutableMultiValueRef) _mutableRef
{
    return ( (ABMutableMultiValueRef)_ref );
}

- (BOOL) addValue: (id) value
        withLabel: (NSString *) label
       identifier: (ABMultiValueIdentifier *) outIdentifier
{
    return ( (BOOL) ABMultiValueAddValueAndLabel([self _mutableRef], (CFTypeRef)value, (CFStringRef)label, outIdentifier) );
}

- (BOOL) insertValue: (id) value
           withLabel: (NSString *) label
             atIndex: (NSUInteger) index
          identifier: (ABMultiValueIdentifier *) outIdentifier
{
    return ( (BOOL) ABMultiValueInsertValueAndLabelAtIndex([self _mutableRef], (CFTypeRef)value, (CFStringRef)label, (CFIndex)index, outIdentifier) );
}

- (BOOL) removeValueAndLabelAtIndex: (NSUInteger) index
{
    return ( (BOOL) ABMultiValueRemoveValueAndLabelAtIndex([self _mutableRef], (CFIndex)index) );
}

- (BOOL) replaceValueAtIndex: (NSUInteger) index withValue: (id) value
{
    return ( (BOOL) ABMultiValueReplaceValueAtIndex([self _mutableRef], (CFTypeRef)value, (CFIndex)index) );
}

- (BOOL) replaceLabelAtIndex: (NSUInteger) index withLabel: (NSString *) label
{
    return ( (BOOL) ABMultiValueReplaceLabelAtIndex([self _mutableRef], (CFStringRef)label, (CFIndex)index) );
}

@end
