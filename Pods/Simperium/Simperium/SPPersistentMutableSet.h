//
//  SPPersistentMutableSet.h
//  Simperium
//
//  Created by Jorge Leandro Perez on 1/14/14.
//  Copyright (c) 2014 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SPPersistentMutableSet : NSObject <NSFastEnumeration>

@property (nonatomic, strong, readonly) NSString *label;

- (void)addObject:(id)object;
- (void)removeObject:(id)object;

- (NSArray *)allObjects;
- (NSUInteger)count;
- (NSSet *)copyInnerSet;

- (void)addObjectsFromArray:(NSArray *)array;
- (void)minusSet:(NSSet *)otherSet;
- (void)removeAllObjects;

- (void)save;
- (void)saveAndWait:(BOOL)wait;

+ (instancetype)loadSetWithLabel:(NSString *)label;

@end
