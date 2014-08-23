//
//  NSMutableDictionary+Simperium.h
//  Simperium
//
//  Created by Michael Johnston on 12-04-18.
//  Copyright (c) 2012 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SPObject;

@interface NSMutableDictionary (Simperium)

@property (nonatomic, copy) NSString *simperiumKey;

- (void)associateObject:(SPObject *)object;
- (void)associateSimperiumKey:(NSString *)key;

@end
