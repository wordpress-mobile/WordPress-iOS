//
//  NSMutableDictionary+Simperium.m
//  Simperium
//
//  Created by Michael Johnston on 12-04-18.
//  Copyright (c) 2012 Simperium. All rights reserved.
//

#import "NSMutableDictionary+Simperium.h"
#import "SPObject.h"
#import "SPBucket+Internals.h"
#import <objc/runtime.h>

static char const * const ObjectKey = "objectKey";
static char const * const SimperiumKey = "simperiumKey";

@implementation NSMutableDictionary (Simperium)

- (void)simperiumSetObject:(id)anObject forKey:(id)aKey {
    
    // Swizzled, not recursive
    [self simperiumSetObject:anObject forKey:aKey];

    // KVOish
    SPObject *spObject = objc_getAssociatedObject(self, ObjectKey);
    NSString *simperiumKey = objc_getAssociatedObject(self, SimperiumKey);

    [spObject.bucket.storage object:self forKey:simperiumKey didChangeValue:anObject forKey:aKey];
}

- (void)simperiumSetValue:(id)anObject forKey:(id)aKey {
    
    // Swizzled, not recursive
    [self simperiumSetValue:anObject forKey:aKey];
    
    // KVOish
    SPObject *spObject = objc_getAssociatedObject(self, ObjectKey);
    NSString *simperiumKey = objc_getAssociatedObject(self, SimperiumKey);
    
    [spObject.bucket.storage object:self forKey:simperiumKey didChangeValue:anObject forKey:aKey];
}

- (NSString *)simperiumKey {
    return objc_getAssociatedObject(self, SimperiumKey);
}

- (void)setSimperiumKey:(NSString *)key {
    objc_setAssociatedObject(self, SimperiumKey, key, OBJC_ASSOCIATION_COPY);        
}

- (void)associateObject:(SPObject *)object {
    objc_setAssociatedObject(self, ObjectKey, object, OBJC_ASSOCIATION_ASSIGN);
}

- (void)associateSimperiumKey:(NSString *)key {
    objc_setAssociatedObject(self, SimperiumKey, key, OBJC_ASSOCIATION_COPY);    
}


@end
