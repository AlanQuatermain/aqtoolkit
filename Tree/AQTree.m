/*
 * AQTree.m
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

#import "AQTree.h"
#if NS_BLOCKS_AVAILABLE
# import <dispatch/dispatch.h>
#endif

@interface AQTreeChildEnumerator : NSEnumerator
{
    AQTree *    _tree;
}
- (id) initWithFirstChild: (AQTree *) firstChild;
@end

@implementation AQTree

@synthesize content=_contentObject, parent=_parent, sibling=_sibling, firstChild=_child;

- (id) initWithContent: (id) contentObject
{
    self = [super init];
    if ( self == nil ) 
        return ( nil );
    
    self.content = contentObject;
    
    return ( self );
}

- (void) dealloc
{
    [_content release];
    [super dealloc];
}

- (id) initWithCoder: (NSCoder *) aDecoder
{
    self = [super init];
    if ( self == nil )
        return ( nil );
    
    self.content = [aDecoder decodeObjectForKey: @"_content"];
    
    NSArray * children = [aDecoder decodeObjectForKey: @"_children"];
    for ( AQTree * child in children )
    {
        [self appendChild: child];
    }
    
    return ( self );
}

- (void) encodeWithCoder: (NSCoder *) aCoder
{
    [aCoder encodeObject: _content forKey: @"_content"];
    [aCoder encodeObject: [self children] forKey: @"_children"];
}

- (NSString *) description
{
    return ( [NSString stringWithFormat: @"<AQTree %p>{children = %u, context = %@}", self, self.numberOfChildren, _content] );
}

- (NSUInteger) numberOfChildren
{
    NSUInteger result = 0;
    AQTree * tree = _child;
    while ( tree != nil )
    {
        result++;
        tree = tree->_sibling;
    }
    return ( result );
}

- (AQTree *) childAtIndex: (NSUInteger) index
{
    AQTree * tree = _child;
    while ( tree != nil )
    {
        if ( index == 0 )
            return ( tree );
        tree = tree->_sibling;
    }
    return ( nil );
}

- (NSArray *) children
{
    NSMutableArray * array = [[NSMutableArray alloc] init];
    AQTree * tree = _child;
    while ( tree != nil )
    {
        [array addObject: tree];
        tree = tree->_sibling;
    }
    NSArray * result = [array copy];
    [array release];
    return ( [result autorelease] );
}

- (void) makeChildrenPerformSelector: (SEL) selector
{
    AQTree * tree = _child;
    while ( tree != nil )
    {
        [tree performSelector: selector];
        tree = tree->_sibling;
    }
}

- (void) makeChildObjectsPerformSelector: (SEL) selector
{
    AQTree * tree = _child;
    while ( tree != nil )
    {
        [tree.content performSelector: selector];
        tree = tree->_sibling;
    }
}

- (AQTree *) root
{
    AQTree * tree = self;
    while ( tree->_parent != nil )
        tree = tree->_parent;
    return ( tree );
}

- (void) prependChild: (AQTree *) newChild
{
    AQTree * currentChild = _child;
    _child = [newChild retain];
    _child->_sibling = currentChild;
    _child->_parent = self;
    _mutationsCounter++;
}

- (void) appendChild: (AQTree *) newChild
{
    if ( _child == nil )
    {
        // this is the only child
        _child = [newChild retain];
        _child->_parent = self;
        _rightmostChild = newChild;
        return;
    }
    
    [newChild retain];      // under non-GC, we always retain children
    _rightmostChild->_sibling = newChild;
    newChild->_parent = self;
    _rightmostChild = newChild;
    _mutationsCounter++;
}

- (void) insertSibling: (AQTree *) newSibling
{
    NSAssert(_parent != nil, "Receiver must have a parent to insert a new sibling");
    newSibling->_sibling = _sibling;
    newSibling->_parent = _parent;
    _sibling = newSibling;
    if ( _parent->_rightmostChild == self )
        _parent->_rightmostChild = newSibling;
    _parent->_mutationsCounter++;
}

- (void) removeFromParent
{
    if ( _parent == nil )
        return;
    
    if ( _parent->_child == self )
    {
        _parent->_child = _sibling;
        if ( _sibling == nil )
            _parent->_rightmostChild = nil;
    }
    else
    {
        AQTree * prevSibling = nil;
        for ( prevSibling = _parent->_child; prevSibling != nil; prevSibling = prevSibling->_sibling )
        {
            if ( prevSibling->_sibling == self )
            {
                prevSibling->_sibling = _sibling;
                if ( _parent->_rightmostChild == self )
                    _parent->_rightmostChild = prevSibling;
                break;
            }
        }
    }
    
    _parent->_mutationsCounter++;
    
    _parent = nil;
    _sibling = nil;
    [self release];
}

- (void) removeAllChildren
{
    AQTree * nextChild = _child;
    _child = nil;
    _rightmostChild = nil;
    _mutationsCounter++;
    
    while ( nextChild != nil )
    {
        AQTree * nextSibling = nextChild->_sibling;
        nextChild->_parent = nil;
        nextChild->_sibling = nil;
        [nextChild release];
        nextChild = nextSibling;
    }
}

static int _qsortCompareTrees( void * arg1, void * arg2, const void * arg3 )
{
    NSArray * descriptors = (NSArray *)arg3;
    NSUInteger i, count = [descriptors count];
    for ( i = 0; i < count; i++ )
    {
        NSComparisonResult cmp = [[descriptors objectAtIndex: i] compareObject: (id)arg1 toObject: (id)arg2];
        if ( cmp != NSOrderedSame )
            return ( cmp );
    }
    return ( 0 );
}

- (void) sortChildrenUsingDescriptors: (NSArray *) descriptors
{
    NSParameterAssert([descriptors count] != 0);
    NSUInteger children = self.numberOfChildren;
    if ( children > 1 )
    {
        NSUInteger idx = 0;
        AQTree * nextChild = nil;
        AQTree ** list, * buffer[128];
        
        list = (children <= 128) ? buffer : NSZoneMalloc([self zone], children * sizeof(AQTree *));
        nextChild = _child;
        for ( idx = 0; nextChild != nil; idx++ )
        {
            // turn off GC while we sort-- saves us coding a GC-aware version of qsort_r or qsort_b
            [[NSGarbageCollector defaultCollector] disableCollectorForPointer: nextChild];
            list[idx] = nextChild;
            nextChild = nextChild->_sibling;
        }
        
        NSUInteger count = [descriptors count];
        
#if NS_BLOCKS_AVAILABLE
        qsort_b( list, children, sizeof(AQTree *), ^ int (const void *arg1, const void *arg2) {
            for ( NSUInteger i = 0; i < count; i++ )
            {
                NSComparisonResult cmp = [[descriptors objectAtIndex: i] compareObject: (id)arg1 toObject: (id)arg2];
                if ( cmp != NSOrderedSame )
                    return ( cmp );
            }
            return ( 0 );
        });
#else
        qsort_r( list, children, sizeof(AQTree *), (void *)descriptors, &_qsortCompareTrees );
#endif
        
        _child = list[0];
        [[NSGarbageCollector defaultCollector] enableCollectorForPointer: _child];
        for ( idx = 1; idx < children; idx++ )
        {
            list[idx-1]->_sibling = list[idx];
            [[NSGarbageCollector defaultCollector] enableCollectorForPointer: list[idx]];
        }
        list[idx-1]->_sibling = nil;
        _rightmostChild = list[children-1];
        
        if ( list != buffer )
            NSZoneFree( [self zone], list );
        
        _mutationsCounter++;
    }
}

- (NSEnumerator *) childEnumerator
{
    if ( _child == nil )
        return ( nil );
    return ( [[[AQTreeChildEnumerator alloc] initWithFirstChild: _child] autorelease] );
}

- (NSUInteger) countByEnumeratingWithState: (NSFastEnumerationState *) state objects: (id *) stackbuf
                                     count: (NSUInteger) len
{
    NSUInteger count = MIN(len, (self.numberOfChildren - state->state));
    state->itemsPtr = stackbuf;
    state->mutationsPtr = &_mutationsCounter;
    
    for ( NSUInteger j = 0, i = state->state; i < count; j++, i++ )
        stackbuf[j] = [self childAtIndex: i];
    
    state->state += count;
    return ( count );
}

#if NS_BLOCKS_AVAILABLE
- (void) enumerateChildrenUsingBlock: (void (^)(AQTree *, NSUInteger, BOOL *)) block
{
    NSUInteger idx = 0;
    BOOL stop = NO;
    AQTree * tree = _child;
    while ( tree != nil )
    {
        block( tree, idx++, &stop );
        if ( stop )
            break;
    }
}

- (void) enumerateChildrenWithOptions: (NSEnumerationOptions) opts
                           usingBlock: (void (^)(AQTree *, NSUInteger, BOOL *)) block
{
    BOOL reverse = (opts & NSEnumerationReverse);
    BOOL dispatch = (opts & NSEnumerationConcurrent);
    NSUInteger idx = (reverse ? self.numberOfChildren-1 : 0);
    __block BOOL stop = NO;
    AQTree * tree = (reverse ? _rightmostChild : _child);
    
    dispatch_group_t group = NULL;
    if ( dispatch )
        group = dispatch_group_create();
    
    while ( tree != nil )
    {
        if ( dispatch )
        {
            dispatch_group_async( group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), 
                            ^{block(tree, idx, &stop);} );
        }
        else
        {
            block( tree, idx, &stop );
            if ( stop )
                break;
        }
        
        if ( reverse )
        {
            idx--;
            tree = [self childAtIndex: idx];
        }
        else
        {
            idx++;
            tree = tree->_sibling;
        }
    }
    
    if ( group != NULL )
        dispatch_group_wait( group, DISPATCH_TIME_FOREVER );
}

- (void) sortChildrenUsingComparator: (NSComparator) cmptr
{
    NSUInteger children = self.numberOfChildren;
    if ( children > 1 )
    {
        NSUInteger idx = 0;
        AQTree * nextChild = nil;
        AQTree ** list, * buffer[128];
        
        list = (children <= 128) ? buffer : NSZoneMalloc([self zone], children * sizeof(AQTree *));
        nextChild = _child;
        for ( idx = 0; nextChild != nil; idx++ )
        {
            // turn off GC while we sort-- saves us coding a GC-aware version of qsort_r or qsort_b
            [[NSGarbageCollector defaultCollector] disableCollectorForPointer: nextChild];
            list[idx] = nextChild;
            nextChild = nextChild->_sibling;
        }
        
        qsort_b(list, children, sizeof(AQTree *), ^ int (const void *arg1, const void *arg2) {
            return ( cmptr((id)arg1, (id)arg2) );
        });
        
        _child = list[0];
        [[NSGarbageCollector defaultCollector] enableCollectorForPointer: _child];
        for ( idx = 1; idx < children; idx++ )
        {
            list[idx-1]->_sibling = list[idx];
            [[NSGarbageCollector defaultCollector] enableCollectorForPointer: list[idx]];
        }
        list[idx-1]->_sibling = nil;
        _rightmostChild = list[children-1];
        
        if ( list != buffer )
            NSZoneFree( [self zone], list );
        
        _mutationsCounter++;
    }
}
#endif

@end

@implementation AQTreeChildEnumerator

- (id) initWithFirstChild: (AQTree *) firstChild
{
    self = [super init];
    if ( self == nil )
        return ( nil );
    
    _tree = [firstChild retain];
    
    return ( self );
}

- (void) dealloc
{
    [_tree release];
    [super dealloc];
}

- (id) nextObject
{
    id result = _tree;
    if ( _tree != nil )
        _tree = _tree.sibling;
    return ( result );
}

@end