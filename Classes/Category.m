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

+ (BOOL)existsName:(NSString *)name forBlogId:(NSString *)blogId withParentId:(NSString *)parentId {
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSArray *items;
    @try {
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Category" 
                                                  inManagedObjectContext:appDelegate.managedObjectContext];
        [request setEntity:entity];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(categoryName like %@) AND (blogId like %@) AND (parentId like %@)", 
                                  name, 
                                  blogId,
                                  (parentId) ? parentId : @"0"];
        [request setPredicate:predicate];
        
        NSError *error;
        items = [appDelegate.managedObjectContext executeFetchRequest:request error:&error];
        [request release];
    }
    @catch (NSException *e) {
        NSLog(@"error checking existence of category: %@", e);
        items = nil;
    }
    
    
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

@end
