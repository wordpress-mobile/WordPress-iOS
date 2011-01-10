// 
//  Post.m
//  WordPress
//
//  Created by Chris Boyd on 8/9/10.
//

#import "Post.h"
#import "WPDataController.h"

@interface Post(PrivateMethods)
+ (Post *)newPostForBlog:(Blog *)blog;
- (void)updateLocalType;
@end

@implementation Post 

@dynamic geolocation, password, tags;
@dynamic categories, comments;

+ (Post *)newPostForBlog:(Blog *)blog {
    Post *post = [[Post alloc] initWithEntity:[NSEntityDescription entityForName:@"Post"
                                                          inManagedObjectContext:[blog managedObjectContext]]
               insertIntoManagedObjectContext:[blog managedObjectContext]];

    post.blog = blog;
    post.local = NO;
    
    return post;
}

+ (Post *)newDraftForBlog:(Blog *)blog {
    Post *post = [self newPostForBlog:blog];
    post.local = YES;
    [post updateLocalType];
    post.dateCreated = [NSDate date];
    [post save];
    
    return post;
}

+ (Post *)findWithBlog:(Blog *)blog andPostID:(NSNumber *)postID {
    NSSet *results = [blog.posts filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"postID == %@",postID]];
    
    if (results && (results.count > 0)) {
        return [[results allObjects] objectAtIndex:0];
    }
    return nil;
}

+ (Post *)createOrReplaceFromDictionary:(NSDictionary *)postInfo forBlog:(Blog *)blog {
    Post *post = [self findWithBlog:blog andPostID:[[postInfo objectForKey:@"postid"] numericValue]];
    
    if (post == nil) {
        post = [[Post newPostForBlog:blog] autorelease];
    }
    
    post.postTitle      = [postInfo objectForKey:@"title"];
    post.postID         = [[postInfo objectForKey:@"postid"] numericValue];
    post.content        = [postInfo objectForKey:@"description"];
    post.dateCreated    = [postInfo objectForKey:@"dateCreated"];
    post.status         = [postInfo objectForKey:@"post_status"];
    NSLog(@"postInfo: %@", postInfo);
    if ([postInfo objectForKey:@"categories"]) {
        [post setCategoriesFromNames:[postInfo objectForKey:@"categories"]];
    }
    
    return post;
}

- (NSArray *)availableStatuses {
    if ([self hasRemote]) {
        return [NSArray arrayWithObjects:
                @"Draft",
                @"Pending review",
                @"Private",
                @"Published",
                nil];
    } else {
        return [NSArray arrayWithObjects:
                @"Local Draft",
                @"Draft",
                @"Pending review",
                @"Private",
                @"Published",
                nil];
    }
}

- (void)save {
    NSError *error;
    if (![[self managedObjectContext] save:&error]) {
        NSLog(@"Unresolved Core Data Save error %@, %@", error, [error userInfo]);
        exit(-1);
    }
}

- (void)upload {
    [super upload];
    [self save];

    self.remoteStatus = AbstractPostRemoteStatusPushing;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    int postID = [[WPDataController sharedInstance] mwNewPost:self];
    if (postID == -1) {
        NSLog(@"Post publish failed");
        self.remoteStatus = AbstractPostRemoteStatusFailed;
    } else {
        self.postID = [NSNumber numberWithInt:postID];
        self.remoteStatus = AbstractPostRemoteStatusSync;
        [self save];
    }
}

- (void)autosave {
    if (self.local) {
        NSError *error = nil;
        if (![[self managedObjectContext] save:&error]) {
            // We better not crash on autosave
            NSLog(@"[Autosave] Unresolved Core Data Save error %@, %@", error, [error userInfo]);
            [FlurryAPI logError:@"Autosave" message:[error localizedDescription] error:error];
        }
    }
}

- (NSString *)categoriesText {
    NSMutableArray *categoryLabels = [NSMutableArray arrayWithCapacity:[self.categories count]];
    for (Category *category in self.categories) {
        [categoryLabels addObject:category.categoryName];
    }
    return [categoryLabels componentsJoinedByString:@", "];
}

- (NSArray *)categoriesDict {
    NSMutableArray *result = [NSMutableArray array];
    for (Category *category in self.categories) {
        NSDictionary *categoryDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                      category.categoryID,
                                      @"categoryId",
                                      category.categoryName,
                                      @"categoryName",
                                      category.parentID,
                                      @"parentId",
                                      nil];
        [result addObject:categoryDict];
    }

    return result;
}

- (void)setCategoriesFromNames:(NSArray *)categoryNames {
    [self.categories removeAllObjects];
    for (NSString *categoryName in categoryNames) {
        NSSet *results = [self.blog.categories filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"categoryName == %@", categoryName]];
        if (results && (results.count > 0)) {
            [self.categories addObject:[[results allObjects] objectAtIndex:0]];
        }
    }
}

- (void)setCategoriesDict:(NSArray *)categoriesDict {
    [self setValue:[NSMutableSet new] forKey:@"categories"];
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    for (NSDictionary *categoryDict in categoriesDict) {
        Category *category;
        NSArray *items;
        @try {
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            NSEntityDescription *entity = [NSEntityDescription entityForName:@"Category"
                                                      inManagedObjectContext:appDelegate.managedObjectContext];
            [request setEntity:entity];

            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(categoryId like %@) AND (blogId like %@)",
                                      [categoryDict objectForKey:@"categoryId"],
                                      self.blog.blogID];
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
            category = [items objectAtIndex:0];
        } else {
            category = [NSEntityDescription insertNewObjectForEntityForName:@"Category" inManagedObjectContext:appDelegate.managedObjectContext];;
            [category setCategoryID:[categoryDict objectForKey:@"categoryId"]];
            [category setCategoryName:[categoryDict objectForKey:@"categoryName"]];
            [category setParentID:[categoryDict objectForKey:@"parentId"]];
            [category setBlog:self.blog];
        }

        NSMutableSet *categories = [self mutableSetValueForKey:@"categories"];
        [categories addObject:category];
        [self setValue:categories forKey:@"categories"];
    }
}

#pragma mark -
#pragma mark Private Methods
- (void)updateLocalType {
    if (self.local) {
        self.localType = @"Local Draft";
    } else {
        self.localType = @"Post";
    }
    
}

@end
