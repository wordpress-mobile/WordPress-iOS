//
//  SPStorage.m
//  Simperium
//
//  Created by Michael Johnston on 11-11-17.
//  Copyright (c) 2011 Simperium. All rights reserved.
//

#import "SPStorage.h"
#import "SPGhost.h"
#import "NSString+Simperium.h"

@implementation SPStorage


- (void)stashUnsavedObjects {
    
}

- (NSArray *)stashedObjects {
    return [stashedObjects allObjects];
}

- (void)unstashUnsavedObjects {
    [stashedObjects removeAllObjects];
}

- (void)unloadAllObjects {
    [stashedObjects removeAllObjects];
}

- (void)stopManagingObjectWithKey:(NSString *)key
{    
    // TODO: check pendingReferences as well just in case? And the stash...    
}

- (void)configureNewGhost:(id<SPDiffable>)object
{
    // It's new to this client, so create an empty ghost for it with version 0
    // (objects coming off the wire already have a ghost, so be careful not to stomp it)
    if (object.ghost == nil) {
        SPGhost *ghost = [[SPGhost alloc] initWithKey: [object simperiumKey] memberData: nil];
        object.ghost = ghost;
        object.ghost.version = @"0";
    }
}

- (void)configureInsertedObject:(id<SPDiffable>)object
{
    if (object.simperiumKey == nil || object.simperiumKey.length == 0) {
        object.simperiumKey = [NSString sp_makeUUID];
	}
    
    [self configureNewGhost:object];
    
    // nil values should be OK now...try disabling defaults
    //[entityManager setDefaults:entity];  
}

@end
