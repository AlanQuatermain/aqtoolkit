//
//  ABRecord.m
//  Skydeck
//
//  Created by Jim Dovey on 05/06/09.
//  Copyright 2009 Morfunk, LLC. All rights reserved.
//

#import "ABRecord.h"
#import "ABMultiValue.h"

#import <AddressBook/ABPerson.h>

static NSMutableIndexSet * __multiValuePropertyIDSet = nil;

@implementation ABRecord

@synthesize recordRef=_ref;

+ (void) initialize
{
    if ( self != [ABRecord class] )
        return;
    
    __multiValuePropertyIDSet = [[NSMutableIndexSet alloc] init];
    [__multiValuePropertyIDSet addIndex: kABPersonEmailProperty];
    [__multiValuePropertyIDSet addIndex: kABPersonAddressProperty];
    [__multiValuePropertyIDSet addIndex: kABPersonDateProperty];
    [__multiValuePropertyIDSet addIndex: kABPersonPhoneProperty];
    [__multiValuePropertyIDSet addIndex: kABPersonInstantMessageProperty];
    [__multiValuePropertyIDSet addIndex: kABPersonURLProperty];
    [__multiValuePropertyIDSet addIndex: kABPersonRelatedNamesProperty];
}

+ (Class<ABRefInitialization>) wrapperClassForPropertyID: (ABPropertyID) propID
{
    if ( [__multiValuePropertyIDSet containsIndex: propID] )
        return ( [ABMultiValue class] );
    
    return ( Nil );
}

- (id) initWithABRef: (CFTypeRef) recordRef
{
    if ( recordRef == NULL )
    {
        [self release];
        return ( nil );
    }
    
    if ( [super init] == nil )
        return ( nil );
    
    // we have to trust the user that the type is correct -- no CFTypeRef checking in AddressBook.framework
    _ref = (ABRecordRef) CFRetain(recordRef);
    
    return ( self );
}

- (void) dealloc
{
    if ( _ref != NULL )
        CFRelease( _ref );
    [super dealloc];
}

- (ABRecordID) recordID
{
    return ( ABRecordGetRecordID(_ref) );
}

- (ABRecordType) recordType
{
    return ( ABRecordGetRecordType(_ref) );
}

- (id) valueForProperty: (ABPropertyID) property
{
    CFTypeRef value = ABRecordCopyValue( _ref, property );
    id result = nil;
    
    Class<ABRefInitialization> wrapperClass = [[self class] wrapperClassForPropertyID: property];
    if ( wrapperClass != Nil )
        result = [[wrapperClass alloc] initWithABRef: value];
    else
        result = (id) value;
    
    return ( [result autorelease] );
}

- (BOOL) setValue: (id) value forProperty: (ABPropertyID) property error: (NSError **) error
{
    if ( [value isKindOfClass: [ABMultiValue class]] )
        value = (id) [value getMultiValueRef];
    return ( (BOOL) ABRecordSetValue(_ref, property, (CFTypeRef)value, (CFErrorRef *)error) );
}

- (BOOL) removeValueForProperty: (ABPropertyID) property error: (NSError **) error
{
    return ( (BOOL) ABRecordRemoveValue(_ref, property, (CFErrorRef *)error) );
}

- (NSString *) compositeName
{
    NSString * result = (NSString *) ABRecordCopyCompositeName( _ref );
    return ( [result autorelease] );
}

@end
