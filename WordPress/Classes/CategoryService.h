//
//  CategoryService.h
//  WordPress
//
//  Created by Aaron Douglas on 3/18/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Category;

@interface CategoryService : NSObject

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context;

- (BOOL)existsName:(NSString *)name forBlogObjectID:(NSManagedObjectID *)blogObjectID withParentId:(NSNumber *)parentId;

- (Category *)findWithBlogObjectID:(NSManagedObjectID *)blogObjectID andCategoryID:(NSNumber *)categoryID;

// Takes the NSDictionary from a XMLRPC call and creates or updates a post
- (Category *)createOrReplaceFromDictionary:(NSDictionary *)categoryInfo forBlogObjectID:(NSManagedObjectID *)blogObjectID;
- (void)createCategoryWithName:(NSString *)name
        parentCategoryObjectID:(NSManagedObjectID *)parentCategoryObjectID
               forBlogObjectID:(NSManagedObjectID *)blogObjectID
                       success:(void (^)(Category *category))success
                       failure:(void (^)(NSError *error))failure;
- (void)mergeNewCategories:(NSArray *)newCategories forBlogObjectID:(NSManagedObjectID *)blogObjectID;


@end
