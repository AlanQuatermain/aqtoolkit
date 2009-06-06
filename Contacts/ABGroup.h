//
//  ABGroup.h
//  Skydeck
//
//  Created by Jim Dovey on 06/06/09.
//  Copyright 2009 Morfunk, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/ABGroup.h>
#import "ABRecord.h"

@class ABPerson;

@interface ABGroup : ABRecord

// use -init to create a new group

- (NSArray *) allMembers;
- (NSArray *) allMembersSortedInOrder: (ABPersonSortOrdering) order;

- (BOOL) addMember: (ABPerson *) person error: (NSError **) error;
- (BOOL) removeMember: (ABPerson *) person error: (NSError **) error;

- (NSIndexSet *) indexSetWithAllMemberRecordIDs;

@end
