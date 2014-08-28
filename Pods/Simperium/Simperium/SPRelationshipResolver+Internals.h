//
//  SPRelationshipResolver+Internals.h
//  Simperium
//
//  Created by Jorge Leandro Perez on 4/23/14.
//  Copyright (c) 2014 Simperium. All rights reserved.
//

#import "SPRelationshipResolver.h"



#pragma mark ====================================================================================
#pragma mark Private Methods
#pragma mark ====================================================================================

@interface SPRelationshipResolver ()


// Note:
// The following methods are DEBUG only, since they're being used by the SPRelationshipResolverTests
// class only, and are intended to be used just to validate inner workings.

#ifdef DEBUG

// Performs a block on the private queue, asynchronously
- (void)performBlock:(void (^)())block;

// Returns the number of pending relationships
- (NSInteger)countPendingRelationships;

// Returns the number of pending relationships between two keys
- (NSInteger)countPendingRelationshipsWithSourceKey:(NSString *)sourceKey andTargetKey:(NSString *)targetKey;

#endif

@end
