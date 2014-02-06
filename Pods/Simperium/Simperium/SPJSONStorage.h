//
//  SPJSONStorage.h
//  Simperium
//
//  Created by Michael Johnston on 11-11-17.
//  Copyright (c) 2011 Simperium. All rights reserved.
//

#import "SPStorage.h"
#import "SPStorageObserver.h"
#import "SPStorageProvider.h"

@interface SPJSONStorage : SPStorage<SPStorageProvider> {
    id<SPStorageObserver> delegate;
    NSMutableDictionary *objects;
    NSMutableDictionary *allObjects;
    NSMutableArray *objectList;
    dispatch_queue_t storageQueue;
}

@property (nonatomic, strong) NSMutableDictionary *objects;
@property (nonatomic, strong) NSMutableDictionary *ghosts;
@property (nonatomic, strong) NSMutableArray *objectList;
@property (nonatomic, strong) NSMutableDictionary *allObjects;

- (id)initWithDelegate:(id<SPStorageObserver>)aDelegate;

@end
