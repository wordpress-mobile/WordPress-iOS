//
//  CoreDataTestHelper.h
//  WordPress
//
//  Created by Jorge Bernal on 2/12/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define CoreDataPerformAndWaitForSave(block) XCTAssertTrue([[CoreDataTestHelper sharedHelper] performAndWaitForSave:block], @"Core Data should have saved");

@interface CoreDataTestHelper : NSObject

@property (nonatomic, copy) void(^saveBlock)();

+ (id)sharedHelper;

- (BOOL)performAndWaitForSave:(void(^)())block;
- (void)reset;

- (void)setModelName:(NSString *)modelName;
- (BOOL)migrateToModelName:(NSString *)modelName;

- (NSManagedObject *)insertEntityIntoMainContextWithName:(NSString *)entityName;
- (NSManagedObject *)insertEntityIntoBackgroundContextWithName:(NSString *)entityName;
- (NSArray *)allObjectsInMainContextForEntityName:(NSString *)entityName;
- (NSArray *)allObjectsInBackgroundContextForEntityName:(NSString *)entityName;

@end
