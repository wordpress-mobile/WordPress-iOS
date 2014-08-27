//
//  SPRelationshipResolver.h
//  Simperium
//
//  Created by Michael Johnston on 2012-08-22.
//  Copyright (c) 2012 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPStorageProvider.h"
#import "SPRelationship.h"



#pragma mark ====================================================================================
#pragma mark SPRelationshipResolver
#pragma mark ====================================================================================

@interface SPRelationshipResolver : NSObject

// Loads Pending Relationships stored in the Storage Provider's Metadata
- (void)loadPendingRelationships:(id<SPStorageProvider>)storage;

// Adds a new pending relationship
- (void)addPendingRelationship:(SPRelationship *)relationship;

// Attempts to establish any pending relationship (from/to) a given object
- (void)resolvePendingRelationshipsForKey:(NSString *)simperiumKey
                               bucketName:(NSString *)bucketName
                                  storage:(id<SPStorageProvider>)storage;

// Persists the Pending Relationships in the Storage's metadata
- (void)saveWithStorage:(id<SPStorageProvider>)storage;

// Nukes all of the pending relationships
- (void)reset:(id<SPStorageProvider>)storage;

@end
