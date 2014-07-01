//
//  SPStorage.h
//  Simperium
//
//  Created by Michael Johnston on 11-11-17.
//  Copyright (c) 2011 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPDiffable.h"

@interface SPStorage : NSObject {
    NSMutableSet *stashedObjects;    
}

- (NSArray *)stashedObjects;
- (void)stopManagingObjectWithKey:(NSString *)key;
- (void)stashUnsavedObjects;
- (void)unstashUnsavedObjects;
- (void)unloadAllObjects;
- (void)configureInsertedObject:(id<SPDiffable>)object;
- (void)configureNewGhost:(id<SPDiffable>)object;
@end
