/*
 * AQTree.h
 * aqtoolkit
 * 
 * Created by Jim Dovey on 26/2/2010.
 * 
 * Copyright (c) 2010 Jim Dovey
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
#import "iPhoneNonatomic.h"

@interface AQTree : NSObject <NSCoding, NSFastEnumeration>
{
    AQTree * _parent;           // not retained
    AQTree * _sibling;          // not retained
    AQTree * _child;            // all children are retained
    AQTree * _rightmostChild;   // not retained
    
    id       _content;
    
    unsigned long   _mutationsCounter;  // used for fast enumeration mutation detection
}

- (id) initWithContent: (id) contentObject;
@property (NS_NONATOMIC_IPHONEONLY retain) id content;

@property (NS_NONATOMIC_IPHONEONLY readonly) AQTree * parent;
@property (NS_NONATOMIC_IPHONEONLY readonly) AQTree * sibling;
@property (NS_NONATOMIC_IPHONEONLY readonly) AQTree * firstChild;
@property (NS_NONATOMIC_IPHONEONLY readonly) NSUInteger numberOfChildren;

- (AQTree *) childAtIndex: (NSUInteger) index;
- (NSArray *) children;
- (void) makeChildrenPerformSelector: (SEL) selector;       // performs selector on the AQTree objects
- (void) makeChildObjectsPerformSelector: (SEL) selector;   // performs selector on the content objects

@property (NS_NONATOMIC_IPHONEONLY readonly) AQTree * root;

- (void) prependChild: (AQTree *) newChild;
- (void) appendChild: (AQTree *) newChild;

- (void) insertSibling: (AQTree *) newSibling;

- (void) removeFromParent;
- (void) removeAllChildren;

- (void) sortChildrenUsingDescriptors: (NSArray *) descriptors;

- (NSEnumerator *) childEnumerator;

#if NS_BLOCKS_AVAILABLE
- (void) enumerateChildrenUsingBlock: (void (^)(AQTree * tree, NSUInteger idx, BOOL *stop)) block;
- (void) enumerateChildrenWithOptions: (NSEnumerationOptions) opts usingBlock: (void (^)(AQTree * tree, NSUInteger idx, BOOL * stop)) block;

- (void) sortChildrenUsingComparator: (NSComparator) cmptr;
#endif

@end
