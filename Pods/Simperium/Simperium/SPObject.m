//
//  SPObject.m
//  Simperium
//
//  Created by Michael Johnston on 12-04-11.
//  Copyright (c) 2012 Simperium. All rights reserved.
//

#import "SPObject.h"
#import "SPGhost.h"
#import "NSMutableDictionary+Simperium.h"

@implementation SPObject
@synthesize dict;
@synthesize ghost;
@synthesize bucket;
@synthesize ghostData;
@synthesize version;

- (instancetype)init {
    self = [self initWithDictionary:[NSMutableDictionary dictionary]];
    if (self) {
    }
    return self;
}

- (instancetype)initWithDictionary:(NSMutableDictionary *)dictionary {
    self = [super init];
    if (self) {
        self.dict = dictionary;
        [self.dict associateObject:self];
        SPGhost *newGhost = [[SPGhost alloc] init];
        self.ghost = newGhost;
    }
    return self;    
}

- (NSString *)simperiumKey {
    return simperiumKey;
}

- (void)setSimperiumKey:(NSString *)key {
    simperiumKey = [key copy];
    
    [self.dict associateSimperiumKey:simperiumKey];
}

// TODO: need to swizzle setObject:forKey: to inform Simperium that data has changed
// This will also need to dynamically update the schema if applicable

// TODO: getters and setters for ghost, ghostData, simperiumKey and version should probably be locked

// These are needed to compose a dict
- (void)simperiumSetValue:(id)value forKey:(NSString *)key {
    dispatch_barrier_async(dispatch_get_main_queue(), ^{
        [dict setObject:value forKey:key];
    });
}

- (id)simperiumValueForKey:(NSString *)key {
    __block id obj;

    dispatch_block_t block = ^{
        obj = [dict objectForKey: key];
    };
    
    // Note: For thread safety reasons, let's use the dictionary just from the main thread
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }

    return obj;
}

- (void)loadMemberData:(NSDictionary *)data {
    dispatch_barrier_async(dispatch_get_main_queue(), ^{
        [dict setValuesForKeysWithDictionary:data];
    });
}

- (void)willBeRead {
    
}

- (NSDictionary *)dictionary {
    return dict;
}

- (id)object {
    return dict;
}


@end
