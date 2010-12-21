//
//  Category.m
//  WordPress
//
//  Created by Jorge Bernal on 10/29/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import "Category.h"


@implementation Category
@dynamic categoryId, categoryName, desc, htmlUrl, parentId, rssUrl, posts, blogId;

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
@end
