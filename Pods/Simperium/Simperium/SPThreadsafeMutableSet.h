//
//  SPThreadsafeMutableSet.h
//  Simperium
//
//  Created by Jorge Leandro Perez on 11/26/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SPThreadsafeMutableSet : NSObject

- (NSArray *)allObjects;
- (BOOL)containsObject:(id)anObject;
- (NSUInteger)count;

- (void)addObject:(id)object;
- (void)removeObject:(id)object;

+ (instancetype)set;

@end
