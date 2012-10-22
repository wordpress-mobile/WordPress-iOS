//
//  Category.m
//  WordPress
//
//  Created by Jorge Bernal on 10/29/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import "Category.h"

@interface Category(PrivateMethods)
+ (Category *)newCategoryForBlog:(Blog *)blog;
@end

@implementation Category
@dynamic categoryID, categoryName, parentID, posts;
@dynamic blog;

+ (Category *)newCategoryForBlog:(Blog *)blog {
    Category *category = [[Category alloc] initWithEntity:[NSEntityDescription entityForName:@"Category"
                                                          inManagedObjectContext:[blog managedObjectContext]]
               insertIntoManagedObjectContext:[blog managedObjectContext]];
    
    category.blog = blog;
    
    return category;
}

+ (BOOL)existsName:(NSString *)name forBlog:(Blog *)blog withParentId:(NSNumber *)parentId {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(categoryName like %@) AND (parentID = %@)", 
                              name,
                              (parentId ? parentId : [NSNumber numberWithInt:0])];
    NSSet *items = [blog.categories filteredSetUsingPredicate:predicate];
    if ((items != nil) && (items.count > 0)) {
        // Already exists
        return YES;
    } else {
        return NO;
    }

}

+ (Category *)findWithBlog:(Blog *)blog andCategoryID:(NSNumber *)categoryID {
    NSSet *results = [blog.categories filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"categoryID == %@",categoryID]];
    
    if (results && (results.count > 0)) {
        return [[results allObjects] objectAtIndex:0];
    }
    return nil;    
}

+ (Category *)createOrReplaceFromDictionary:(NSDictionary *)categoryInfo forBlog:(Blog *)blog {
    if ([categoryInfo objectForKey:@"categoryId"] == nil) {
        return nil;
    }
    if ([categoryInfo objectForKey:@"categoryName"] == nil) {
        return nil;
    }

    Category *category = [self findWithBlog:blog andCategoryID:[[categoryInfo objectForKey:@"categoryId"] numericValue]];
    
    if (category == nil) {
        category = [Category newCategoryForBlog:blog];
    }
    
    category.categoryID     = [[categoryInfo objectForKey:@"categoryId"] numericValue];
    category.categoryName   = [categoryInfo objectForKey:@"categoryName"];
    category.parentID       = [[categoryInfo objectForKey:@"parentId"] numericValue];
    
    return category;
}

+ (void)createCategory:(NSString *)name parent:(Category *)parent forBlog:(Blog *)blog success:(void (^)(Category *category))success failure:(void (^)(NSError *error))failure {
    Category *category = [Category newCategoryForBlog:blog];
    category.categoryName = name;
	if (parent.categoryID != nil)
		category.parentID = parent.categoryID;
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                category.categoryName, @"name",
                                category.parentID, @"parent_id",
                                nil];
    [blog.api callMethod:@"wp.newCategory"
              parameters:[blog getXMLRPCArgsWithExtra:parameters]
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     NSNumber *categoryID = responseObject;
                     int newID = [categoryID intValue];
                     if (newID > 0) {
                         category.categoryID = [categoryID numericValue];
                         [blog dataSave];
                         if (success) {
                             success(category);
                         }
                     }
                 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     WPLog(@"Error while creating category: %@", [error localizedDescription]);
                     // Just in case another thread has saved while we were creating
                     [[blog managedObjectContext] deleteObject:category];
                     [blog dataSave]; // Commit core data changes
                     if (failure) {
                         failure(error);
                     }
                 }];
}
@end
