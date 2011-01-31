//
//  Blog.m
//  WordPress
//
//  Created by Gareth Townsend on 24/06/09.
//

#import "Blog.h"
#import "UIImage+INResizeImageAllocator.h"
#import "WPDataController.h"

@implementation Blog
@dynamic blogID, blogName, url, username, password, xmlrpc, apiKey;
@dynamic isAdmin;
@dynamic posts, categories;

#pragma mark -
#pragma mark Custom methods

+ (BOOL)blogExistsForURL:(NSString *)theURL withContext:(NSManagedObjectContext *)moc {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Blog"
                                        inManagedObjectContext:moc]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"url like %@", theURL]];
    NSError *error = nil;
    NSArray *results = [moc executeFetchRequest:fetchRequest error:&error];
    [fetchRequest release]; fetchRequest = nil;

    return (results.count > 0);
}

+ (Blog *)createFromDictionary:(NSDictionary *)blogInfo withContext:(NSManagedObjectContext *)moc {
    Blog *blog = nil;
    NSString *blogUrl = [[blogInfo objectForKey:@"url"] stringByReplacingOccurrencesOfString:@"http://" withString:@""];
	if([blogUrl hasSuffix:@"/"])
		blogUrl = [blogUrl substringToIndex:blogUrl.length-1];
	blogUrl= [blogUrl stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    if (![self blogExistsForURL:blogUrl withContext:moc]) {
        blog = [[[Blog alloc] initWithEntity:[NSEntityDescription entityForName:@"Blog"
                                                              inManagedObjectContext:moc]
             insertIntoManagedObjectContext:moc] autorelease];

        blog.url = blogUrl;
        blog.blogID = [NSNumber numberWithInt:[[blogInfo objectForKey:@"blogid"] intValue]];
        blog.blogName = [blogInfo objectForKey:@"blogName"];
		blog.xmlrpc = [blogInfo objectForKey:@"xmlrpc"];
        blog.username = [blogInfo objectForKey:@"username"];
        blog.isAdmin = [NSNumber numberWithInt:[[blogInfo objectForKey:@"isAdmin"] intValue]];

        NSError *error = nil;
        [SFHFKeychainUtils storeUsername:[blogInfo objectForKey:@"username"]
                             andPassword:[blogInfo objectForKey:@"password"]
                          forServiceName:blog.url
                          updateExisting:TRUE
                                   error:&error ];
        // TODO: save blog settings
	}
    return blog;
}

+ (NSInteger)countWithContext:(NSManagedObjectContext *)moc {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Blog" inManagedObjectContext:moc]];
    [request setIncludesSubentities:NO];

    NSError *err;
    NSUInteger count = [moc countForFetchRequest:request error:&err];
    [request release];
    if(count == NSNotFound) {
        count = 0;
    }
    return count;
}

- (UIImage *)favicon {
    UIImage *faviconImage = nil;
    NSString *fileName = [NSString stringWithFormat:@"favicon-%@-%@.png", self.hostURL, self.blogID];
	fileName = [fileName stringByReplacingOccurrencesOfRegex:@"http(s?)://" withString:@""];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *faviconFilePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:fileName];
	
    if ([[NSFileManager defaultManager] fileExistsAtPath:faviconFilePath] == YES) {
        faviconImage = [UIImage imageWithContentsOfFile:faviconFilePath];
    }
	else {
		faviconImage = [UIImage imageNamed:@"favicon"];
		[self downloadFavicon];
	}

    return faviconImage;
}

- (void)downloadFaviconInBackground {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *faviconURL = [NSString stringWithFormat:@"%@/favicon.ico", self.url];
	if(![faviconURL hasPrefix:@"http"])
		faviconURL = [NSString stringWithFormat:@"http://%@", faviconURL];
	
    NSString *fileName = [NSString stringWithFormat:@"favicon-%@-%@.png", self.blogName, self.blogID];
	fileName = [fileName stringByReplacingOccurrencesOfRegex:@"http(s?)://" withString:@""];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *faviconFilePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:fileName];
	UIImage *faviconImage = [[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:faviconURL]]] scaleImageToSize:CGSizeMake(16.0f, 16.0f)];
	
	if (faviconImage != NULL) {
		//[[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:nil];
		[[NSFileManager defaultManager] createFileAtPath:faviconFilePath contents:UIImagePNGRepresentation(faviconImage) attributes:nil];
	}

	
	[pool release];
}

- (void)downloadFavicon {
	[self performSelectorInBackground:@selector(downloadFaviconInBackground) withObject:nil];
}

- (NSString *)hostURL {
    NSString *result = [NSString stringWithFormat:@"%@",
                         [self.url stringByReplacingOccurrencesOfRegex:@"http(s?)://" withString:@""]];

    if([result hasSuffix:@"/"])
        result = [result substringToIndex:[result length] - 1];

    return result;
}

- (BOOL)isWPcom {
    NSRange range = [self.url rangeOfString:@"wordpress.com"];
	return (range.location != NSNotFound);
}

- (void)dataSave {
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        NSLog(@"Unresolved Core Data Save error %@, %@", error, [error userInfo]);
        exit(-1);
    }
}

#pragma mark -
#pragma mark Synchronization

- (NSArray *)syncedPostsWithEntityName:(NSString *)entityName {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:[self managedObjectContext]]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(remoteStatusNumber = %@) AND (postID != NULL) AND (original == NULL)", [NSNumber numberWithInt:AbstractPostRemoteStatusSync]];
    [request setPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"postID" ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    [sortDescriptor release];
    
    NSError *error = nil;
    NSArray *array = [[self managedObjectContext] executeFetchRequest:request error:&error];
    [request release];
    if (array == nil) {
        array = [NSArray array];
    }
    return array;
}

- (NSArray *)syncedPosts {
    return [self syncedPostsWithEntityName:@"Post"];
}

- (BOOL)syncPostsFromResults:(NSMutableArray *)posts {
    if ([posts count] == 0)
        return NO;

    NSArray *syncedPosts = [self syncedPosts];
    NSMutableArray *postsToKeep = [NSMutableArray array];
    for (NSDictionary *postInfo in posts) {
        [postsToKeep addObject:[Post createOrReplaceFromDictionary:postInfo forBlog:self]];
    }
    for (Post *post in syncedPosts) {
        if (![postsToKeep containsObject:post]) {
            if (post.revision) {
                // If there is a revision, we are editing this post
                post.remoteStatus = AbstractPostRemoteStatusLocal;
                post.postID = nil;
            } else {
                WPLog(@"Deleting post: %@", post);                
                [[self managedObjectContext] deleteObject:post];
            }
        }
    }

    [self dataSave];
    return YES;
}

- (BOOL)syncPostsWithError:(NSError **)error {    
    NSMutableArray *posts = [[WPDataController sharedInstance] getRecentPostsForBlog:self];
    if ([posts isKindOfClass:[NSError class]]) {
        if (error != nil) {
            *error = (NSError *)posts;
            // TODO: show alert to user?
            NSLog(@"Error syncing blog posts: %@", [*error localizedDescription]);            
        }
        return NO;
    }
    [self performSelectorOnMainThread:@selector(syncPostsFromResults:) withObject:posts waitUntilDone:YES];

    return YES;
}

- (NSArray *)syncedPages {
    return [self syncedPostsWithEntityName:@"Page"];
}

- (BOOL)syncPagesFromResults:(NSMutableArray *)pages {
    if ([pages count] == 0)
        return NO;

    NSArray *syncedPages = [self syncedPages];
    NSMutableArray *pagesToKeep = [NSMutableArray array];
    for (NSDictionary *pageInfo in pages) {
        [pagesToKeep addObject:[Page createOrReplaceFromDictionary:pageInfo forBlog:self]];
    }
    for (Page *page in syncedPages) {
        if (![pagesToKeep containsObject:page]) {
            if (page.revision) {
                // If there is a revision, we are editing this post
                page.remoteStatus = AbstractPostRemoteStatusLocal;
                page.postID = nil;
            } else {
                WPLog(@"Deleting page: %@", page);
                [[self managedObjectContext] deleteObject:page];
            }
        }
    }

    [self dataSave];
    return YES;
}

- (BOOL)syncPagesWithError:(NSError **)error {    
    NSMutableArray *pages = [[WPDataController sharedInstance] wpGetPages:self];
    if ([pages isKindOfClass:[NSError class]]) {
        if (error != nil) {
            *error = (NSError *)pages;
            // TODO: show alert to user?
            NSLog(@"Error syncing blog pages: %@", [*error localizedDescription]);
        }
        return NO;
    }
    [self performSelectorOnMainThread:@selector(syncPagesFromResults:) withObject:pages waitUntilDone:YES];
    
    return YES;
}

- (BOOL)syncCategoriesFromResults:(NSMutableArray *)categories {
    for (NSDictionary *categoryInfo in categories) {
        [Category createOrReplaceFromDictionary:categoryInfo forBlog:self];
    }
    [self dataSave];
    return YES;
}

- (BOOL)syncCategoriesWithError:(NSError **)error {
    NSMutableArray *categories = [[WPDataController sharedInstance] getCategoriesForBlog:self];
    if ([categories isKindOfClass:[NSError class]]) {
        if (error != nil) {
            *error = (NSError *)categories;
            // TODO: show alert to user?
            NSLog(@"Error syncing categories: %@", [*error localizedDescription]);
        }
        return NO;
    }
    [self performSelectorOnMainThread:@selector(syncCategoriesFromResults:) withObject:categories waitUntilDone:YES];

    return YES;
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
    [super dealloc];
}

@end
