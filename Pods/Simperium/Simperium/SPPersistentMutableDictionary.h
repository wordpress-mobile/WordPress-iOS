//
//  SPPersistentMutableDictionary.h
//  Simperium
//
//  Created by Jorge Leandro Perez on 9/12/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import <Foundation/Foundation.h>



#pragma mark ====================================================================================
#pragma mark SPPersistentMutableDictionary
#pragma mark ====================================================================================

@interface SPPersistentMutableDictionary : NSObject

@property (nonatomic, strong, readonly) NSString *label;

- (NSInteger)count;
- (BOOL)containsObjectForKey:(id)aKey;

- (id)objectForKey:(NSString*)aKey;
- (void)setObject:(id)anObject forKey:(NSString*)aKey;
- (BOOL)save;

- (NSArray*)allKeys;
- (NSArray*)allValues;

- (void)removeObjectForKey:(id)aKey;
- (void)removeAllObjects;

+ (instancetype)loadDictionaryWithLabel:(NSString *)label;

@end
