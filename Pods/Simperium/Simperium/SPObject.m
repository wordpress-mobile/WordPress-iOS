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

- (id)init {
    if ((self = [self initWithDictionary:[NSMutableDictionary dictionary]])) {
    }
    return self;
}

- (id)initWithDictionary:(NSMutableDictionary *)dictionary {
    if ((self = [super init])) {
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
    dispatch_sync(dispatch_get_main_queue(), ^{
        obj = [dict objectForKey: key];
    });
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
