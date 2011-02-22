//
//  Category.m
//  WordPress
//
//  Created by Jorge Bernal on 10/29/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import "Category.h"
#import "WPDataController.h"

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
        category = [[Category newCategoryForBlog:blog] autorelease];
    }
    
    category.categoryID     = [[categoryInfo objectForKey:@"categoryId"] numericValue];
    category.categoryName   = [categoryInfo objectForKey:@"categoryName"];
    category.parentID       = [[categoryInfo objectForKey:@"parentId"] numericValue];
    
    return category;
}

+ (Category *)createCategoryWithError:(NSString *)name parent:(Category *)parent forBlog:(Blog *)blog error:(NSError **)error{
    Category *category = [Category newCategoryForBlog:blog];
	WPDataController *dc = [[WPDataController alloc] init];
    category.categoryName = name;
	if (parent.categoryID != nil)
		category.parentID = parent.categoryID;
    int newID = [dc wpNewCategory:category];
	if(dc.error) {
		if (error != nil) 
			*error = dc.error;
		WPLog(@"Error while creating category: %@", [dc.error localizedDescription]);
	}
    if (newID > 0 && !dc.error) {
        category.categoryID = [NSNumber numberWithInt:newID];
        [blog dataSave]; // Commit core data changes
		[dc release];
        return [category autorelease];
    } else {
        // Just in case another thread has saved while we were creating
        [[blog managedObjectContext] deleteObject:category];
		[blog dataSave]; // Commit core data changes
        [category release];
		[dc release];
        return nil;
    }
}
@end
