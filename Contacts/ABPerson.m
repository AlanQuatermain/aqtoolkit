/*
 * ABPerson.m
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

#import "ABPerson.h"

@implementation ABPerson

+ (ABPropertyType) typeOfProperty: (ABPropertyID) property
{
    return ( ABPersonGetTypeOfProperty(property) );
}

+ (NSString *) localizedNameOfProperty: (ABPropertyID) property
{
    NSString * name = (NSString *) ABPersonCopyLocalizedPropertyName(property);
    return ( [name autorelease] );
}

+ (ABPersonSortOrdering) sortOrdering
{
    return ( ABPersonGetSortOrdering() );
}

+ (ABPersonCompositeNameFormat) compositeNameFormat
{
    return ( ABPersonGetCompositeNameFormat() );
}

- (id) init
{
    ABRecordRef person = ABPersonCreate();
    if ( person == NULL )
    {
        [self release];
        return ( nil );
    }
    
    return ( [self initWithABRef: person] );
}

- (BOOL) setImageData: (NSData *) imageData error: (NSError **) error
{
    return ( (BOOL) ABPersonSetImageData(_ref, (CFDataRef)imageData, (CFErrorRef *)error) );
}

- (NSData *) imageData
{
    NSData * imageData = (NSData *) ABPersonCopyImageData( _ref );
    return ( [imageData autorelease] );
}

- (BOOL) hasImageData
{
    return ( (BOOL) ABPersonHasImageData(_ref) );
}

- (BOOL) removeImageData: (NSError **) error
{
    return ( (BOOL) ABPersonRemoveImageData(_ref, (CFErrorRef *)error) );
}

- (NSComparisonResult) compare: (ABPerson *) otherPerson
{
    return ( [self compare: otherPerson sortOrdering: ABPersonGetSortOrdering()] );
}

- (NSComparisonResult) compare: (ABPerson *) otherPerson sortOrdering: (ABPersonSortOrdering) order
{
    return ( (NSComparisonResult) ABPersonComparePeopleByName(_ref, otherPerson->_ref, order) );
}

@end
