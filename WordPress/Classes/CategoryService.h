/*
 * CategoryService.h
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <Foundation/Foundation.h>

@class Category;

@interface CategoryService : NSObject

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context;

- (BOOL)existsName:(NSString *)name forBlogObjectID:(NSManagedObjectID *)blogObjectID withParentId:(NSNumber *)parentId;

- (Category *)findWithBlogObjectID:(NSManagedObjectID *)blogObjectID andCategoryID:(NSNumber *)categoryID;

- (void)createCategoryWithName:(NSString *)name
        parentCategoryObjectID:(NSManagedObjectID *)parentCategoryObjectID
               forBlogObjectID:(NSManagedObjectID *)blogObjectID
                       success:(void (^)(Category *category))success
                       failure:(void (^)(NSError *error))failure;

- (void)mergeNewCategories:(NSArray *)newCategories forBlogObjectID:(NSManagedObjectID *)blogObjectID;


@end
