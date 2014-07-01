//
//  SPRelationshipResolver.h
//  Simperium
//
//  Created by Michael Johnston on 2012-08-22.
//  Copyright (c) 2012 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPStorageProvider.h"



#pragma mark ====================================================================================
#pragma mark SPRelationshipResolver
#pragma mark ====================================================================================

@interface SPRelationshipResolver : NSObject

- (void)loadPendingRelationships:(id<SPStorageProvider>)storage;
- (void)addPendingRelationshipToKey:(NSString *)key fromKey:(NSString *)fromKey bucketName:(NSString *)bucketName
                   attributeName:(NSString *)attributeName storage:(id<SPStorageProvider>)storage;
- (void)resolvePendingRelationshipsToKey:(NSString *)toKey bucketName:(NSString *)bucketName storage:(id<SPStorageProvider>)storage;
- (void)reset:(id<SPStorageProvider>)storage;

@end
