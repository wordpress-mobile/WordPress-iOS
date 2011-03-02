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
@dynamic isAdmin, hasOlderPosts, hasOlderPages;
@dynamic posts, categories, comments; 
@dynamic lastPostsSync, lastStatsSync, lastPagesSync, lastCommentsSync;
@synthesize isSyncingPosts, isSyncingPages, isSyncingComments;
@dynamic geolocationEnabled;

- (BOOL)geolocationEnabled 
{
    BOOL tmpValue;
    
    [self willAccessValueForKey:@"geolocationEnabled"];
    tmpValue = [[self primitiveValueForKey:@"geolocationEnabled"] boolValue];
    [self didAccessValueForKey:@"geolocationEnabled"];
    
    return tmpValue;
}

- (void)setGeolocationEnabled:(BOOL)value 
{
    [self willChangeValueForKey:@"geolocationEnabled"];
    [self setPrimitiveValue:[NSNumber numberWithBool:value] forKey:@"geolocationEnabled"];
    [self didChangeValueForKey:@"geolocationEnabled"];
}

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
                          forServiceName:blog.hostURL
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
	
    NSString *fileName = [NSString stringWithFormat:@"favicon-%@-%@.png", self.hostURL, self.blogID];
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
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(remoteStatusNumber = %@) AND (postID != NULL) AND (original == NULL) AND (blog.blogID = %@)",
							  [NSNumber numberWithInt:AbstractPostRemoteStatusSync], self.blogID]; 
    [request setPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date_created_gmt" ascending:YES];
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
		
        if (![postsToKeep containsObject:post]) {  /*&& post.blog.blogID == self.blogID*/
			//the current stored post is not contained "as-is" on the server response

            if (post.revision) { //edited post before the refresh is finished
				//We should check if this post is already available on the blog
				BOOL presence = NO; 
				
				for (Post *currentPostToKeep in postsToKeep) {
					if([currentPostToKeep.postID isEqualToNumber:post.postID]) {
						presence = YES;
						break;
					}
				}
				if( presence == YES ) {
					//post is on the server (most cases), kept it unchanged
					
				} else {
					//post is deleted on the server, make it local, otherwise you can't upload it anymore
					post.remoteStatus = AbstractPostRemoteStatusLocal;
					post.postID = nil;
					
				}
			} else {
				//post is not on the server anymore. delete it.
                WPLog(@"Deleting post: %@", post);                
                [[self managedObjectContext] deleteObject:post];
            }
        }
    }
	
    [self dataSave];
    return YES;
}

- (BOOL)syncPostsWithError:(NSError **)error loadMore:(BOOL)more {
    if (self.isSyncingPosts) {
        WPLog(@"Already syncing posts. Skip");
        return NO;
    }
    self.isSyncingPosts = YES;
    int num;

    // Don't load more than 20 posts if we aren't at the end of the table,
    // even if they were previously donwloaded
    // 
    // Blogs with long history can get really slow really fast, 
    // with no chance to go back
    if (more) {
        num = MAX([self.posts count], 20);
        if ([self.hasOlderPosts boolValue]) {
            num += 20;
        }
    } else {
        num = 20;
    }

    WPLog(@"Loading %i posts...", num);
	WPDataController *dc = [[WPDataController alloc] init];
	NSMutableArray *posts = [dc getRecentPostsForBlog:self number:[NSNumber numberWithInt:num]];
	if(dc.error) {
		if (error != nil) 
			*error = dc.error;
		WPLog(@"Error syncing blog posts: %@", [dc.error localizedDescription]);
		[dc release];
		self.isSyncingPosts = NO;
		return NO;
	}
	
    // If we asked for more and we got what we had, there are no more posts to load
    if (more && ([posts count] <= [self.posts count])) {
        self.hasOlderPosts = [NSNumber numberWithBool:NO];
    } else if (!more) {
		//we should reset the flag otherwise when you refresh this blog you can't get more than 20 posts
		self.hasOlderPosts = [NSNumber numberWithBool:YES];
	}
    [self performSelectorOnMainThread:@selector(syncPostsFromResults:) withObject:posts waitUntilDone:YES];
    self.lastPostsSync = [NSDate date];
    self.isSyncingPosts = NO;
	[dc release];
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
		if (![pagesToKeep containsObject:page]) { /*&& page.blog.blogID == self.blogID*/

			if (page.revision) { //edited page before the refresh is finished
				//We should check if this page is already available on the blog
				BOOL presence = NO; 
				
				for (Page *currentPageToKeep in pagesToKeep) {
					if([currentPageToKeep.postID isEqualToNumber:page.postID]) {
						presence = YES;
						break;
					}
				}
				if( presence == YES ) {
					//page is on the server (most cases), kept it unchanged
					
				} else {
					//page is deleted on the server, make it local, otherwise you can't upload it anymore
					page.remoteStatus = AbstractPostRemoteStatusLocal;
					page.postID = nil;
					
				}
			} else {
				//page is not on the server anymore. delete it.
                WPLog(@"Deleting page: %@", page);
                [[self managedObjectContext] deleteObject:page];
            }
        }
    }

    [self dataSave];
    return YES;
}

- (BOOL)syncPagesWithError:(NSError **)error loadMore:(BOOL)more {
	if (self.isSyncingPages) {
        WPLog(@"Already syncing pages. Skip");
        return NO;
    }
    self.isSyncingPages = YES;
    int num;
	
    // Don't load more than 10 pages if we aren't at the end of the table,
    // even if they were previously donwloaded
    // 
    // Blogs with long history can get really slow really fast, 
    // with no chance to go back
    if (more) {
        num = MAX([[self syncedPages] count], 10);
        if ([self.hasOlderPages boolValue]) {
            num += 10;
        }
    } else {
        num = 10;
    }
	
    WPLog(@"Loading %i pages...", num);
	WPDataController *dc = [[WPDataController alloc] init];
	NSMutableArray *pages = [dc wpGetPages:self number:[NSNumber numberWithInt:num]];
	
	if(dc.error) {
		if (error != nil) 
			*error = dc.error;
		WPLog(@"Error syncing blog pages: %@", [dc.error localizedDescription]);
		[dc release];
		self.isSyncingPages = NO;
		return NO;
	}
	
	// If we asked for more and we got what we had, there are no more posts to load
    if (more && ([pages count] <= [[self syncedPages] count])) {
        self.hasOlderPages = [NSNumber numberWithBool:NO];
    } else if (!more) {
		self.hasOlderPages = [NSNumber numberWithBool:YES];
	}
	
    [self performSelectorOnMainThread:@selector(syncPagesFromResults:) withObject:pages waitUntilDone:YES];	
	self.lastPagesSync = [NSDate date];
    self.isSyncingPages = NO;
	[dc release];
    return YES;
}



- (BOOL)syncCategoriesFromResults:(NSMutableArray *)categories {
	
	NSMutableArray *categoriesToKeep = [NSMutableArray array];
    for (NSDictionary *categoryInfo in categories) {
		[categoriesToKeep addObject:[Category createOrReplaceFromDictionary:categoryInfo forBlog:self]];
    }
	
	NSSet *syncedCategories = self.categories;
	if (syncedCategories && (syncedCategories.count > 0)) {
		for (Category *cat in syncedCategories) {
			if(![categoriesToKeep containsObject:cat]) {
				WPLog(@"Deleting Category: %@", cat);
				[[self managedObjectContext] deleteObject:cat];
			}
		}
    }
	
    [self dataSave];
    return YES;
}

- (BOOL)syncCategoriesWithError:(NSError **)error {
	WPDataController *dc = [[WPDataController alloc] init];
	NSMutableArray *categories = [dc getCategoriesForBlog:self];
	if(dc.error) {
		if (error != nil) 
			*error = dc.error;
		 WPLog(@"Error syncing categories: %@", [dc.error localizedDescription]);
		[dc release];
		return NO;
	}
    [self performSelectorOnMainThread:@selector(syncCategoriesFromResults:) withObject:categories waitUntilDone:YES];
    [dc release];
	return YES;
}


- (BOOL)syncCommentsFromResults:(NSMutableArray *)comments {
    if ([self isDeleted])
        return NO;
	
	NSMutableArray *commentsToKeep = [NSMutableArray array];
    for (NSDictionary *commentInfo in comments) {
        [commentsToKeep addObject:[Comment createOrReplaceFromDictionary:commentInfo forBlog:self]];
    }
	
	NSSet *syncedComments = self.comments;
    if (syncedComments && (syncedComments.count > 0)) {
		for (Comment *comment in syncedComments) {
			// Don't delete unpublished comments
			if(![commentsToKeep containsObject:comment] && comment.commentID != nil) {
				WPLog(@"Deleting Comment: %@", comment);
				[[self managedObjectContext] deleteObject:comment];
			}
		}
    }
	
    [self dataSave];
    return YES;
}

- (BOOL)syncCommentsWithError:(NSError **)error {
	if (self.isSyncingComments) {
        WPLog(@"Already syncing comments. Skip");
        return NO;
    }
    self.isSyncingComments = YES;
	
	WPDataController *dc = [[WPDataController alloc] init];
    NSMutableArray *comments = [dc wpGetCommentsForBlog:self];
	if(dc.error) {
		if (error != nil) 
			*error = dc.error;
		self.isSyncingComments = NO;
		WPLog(@"Error syncing comments: %@", [dc.error localizedDescription]);
		[dc release];
		return NO;
	}
	
    [self performSelectorOnMainThread:@selector(syncCommentsFromResults:) withObject:comments waitUntilDone:YES];
    
	self.lastCommentsSync = [NSDate date];
    self.isSyncingComments = NO;
	[dc release];
    return YES;
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
    [super dealloc];
}

@end
