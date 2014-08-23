//
//  TestObject.m
//  SimperiumTests
//
//  Created by Michael Johnston on 11-03-08.
//  Copyright 2011 Simperium. All rights reserved.
//

#import "TestObject.h"


@implementation TestObject

- (NSString *)description {
    return @"no test object";
}

- (BOOL)isEqualToObject:(TestObject *)other {
    return NO;
}

+ (NSString *)entityName {
	return NSStringFromClass([self class]);
}

@end
