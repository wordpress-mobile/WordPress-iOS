//
//  Blog.m
//  WordPress
//
//  Created by Gareth Townsend on 24/06/09.
//

#import "Blog.h"
#import "UIImage+Resize.h"
#import "WPDataController.h"
#import "NSURL+IDN.h"

@interface Blog (PrivateMethods)
- (NSArray *)getXMLRPCArgsWithExtra:(id)extra;
- (NSString *)fetchPassword;

- (AFXMLRPCRequestOperation *)operationForOptionsWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (AFXMLRPCRequestOperation *)operationForPostFormatsWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (AFXMLRPCRequestOperation *)operationForCommentsWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (AFXMLRPCRequestOperation *)operationForCategoriesWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (AFXMLRPCRequestOperation *)operationForPostsWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure loadMore:(BOOL)more;
- (AFXMLRPCRequestOperation *)operationForPagesWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure loadMore:(BOOL)more;

- (void)mergeCategories:(NSArray *)newCategories;
- (void)mergeComments:(NSArray *)newComments;
- (void)mergePages:(NSArray *)newPages;
- (void)mergePosts:(NSArray *)newPosts;
@end


@implementation Blog {
    AFXMLRPCClient *_api;
    NSString *_blavatarUrl;
}
@dynamic blogID, blogName, url, username, password, xmlrpc, apiKey;
@dynamic isAdmin, hasOlderPosts, hasOlderPages;
@dynamic posts, categories, comments; 
@dynamic lastPostsSync, lastStatsSync, lastPagesSync, lastCommentsSync;
@synthesize isSyncingPosts, isSyncingPages, isSyncingComments;
@dynamic geolocationEnabled, options, postFormats;

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

+ (BOOL)blogExistsForURL:(NSString *)theURL withContext:(NSManagedObjectContext *)moc andUsername:(NSString *)username{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Blog"
                                        inManagedObjectContext:moc]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"url like %@ AND username = %@", theURL, username]];
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
    
    if (![self blogExistsForURL:blogUrl withContext:moc andUsername: [blogInfo objectForKey:@"username"]]) {
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

- (NSString *)blavatarUrl {
	if (_blavatarUrl == nil) {
        NSString *hostUrl = [[NSURL URLWithString:self.xmlrpc] host];
        if (hostUrl == nil) {
            hostUrl = self.xmlrpc;
        }
		
        _blavatarUrl = [hostUrl retain];
    }

    return _blavatarUrl;
}


- (NSString *)hostURL {
    NSString *result = [NSString stringWithFormat:@"%@",
                        [[NSURL IDNDecodedHostname:self.url] stringByReplacingOccurrencesOfRegex:@"http(s?)://" withString:@""]];
    
    if([result hasSuffix:@"/"])
        result = [result substringToIndex:[result length] - 1];
    
    return result;
}


- (NSString *)blogLoginURL {
    return [self.xmlrpc stringByReplacingOccurrencesOfRegex:@"/xmlrpc.php$" withString:@"/wp-login.php"];
    /*
     i have used the blogURL and worked fine, but the xmlrpc url should be a better choice since it is usually on https.
     
     if(![wpLoginURL hasPrefix:@"http"])
     wpLoginURL = [NSString stringWithFormat:@"http://%@/%@", postDetailViewController.apost.blog.url, @"wp-login.php"];
     else 
     wpLoginURL = [NSString stringWithFormat:@"%@/%@", postDetailViewController.apost.blog.url, @"wp-login.php"];
     
     */
}

-(NSArray *)sortedCategories {
	NSSortDescriptor *sortNameDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"categoryName" 
																		ascending:YES 
																		 selector:@selector(caseInsensitiveCompare:)] autorelease];
	NSArray *sortDescriptors = [[[NSArray alloc] initWithObjects:sortNameDescriptor, nil] autorelease];
	
	return [[self.categories allObjects] sortedArrayUsingDescriptors:sortDescriptors];
}

- (BOOL)isWPcom {
    NSRange range = [self.xmlrpc rangeOfString:@"wordpress.com"];
	return (range.location != NSNotFound);
}

- (void)dataSave {
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        WPFLog(@"Unresolved Core Data Save error %@, %@", error, [error userInfo]);
        exit(-1);
    }
}

- (void)setXmlrpc:(NSString *)xmlrpc {
    [self willChangeValueForKey:@"xmlrpc"];
    [self setPrimitiveValue:xmlrpc forKey:@"xmlrpc"];
    [self didChangeValueForKey:@"xmlrpc"];
    [_blavatarUrl release]; _blavatarUrl = nil;

    // Reset the api client so next time we use the new XML-RPC URL
    [_api release]; _api = nil;
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

- (void)syncPostsWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure loadMore:(BOOL)more {
    if (self.isSyncingPosts) {
        WPLog(@"Already syncing posts. Skip");
        return;
    }
    self.isSyncingPosts = YES;

    AFXMLRPCRequestOperation *operation = [self operationForPostsWithSuccess:success failure:failure loadMore:more];
    [self.api enqueueHTTPRequestOperation:operation];
}

- (NSArray *)syncedPages {
    return [self syncedPostsWithEntityName:@"Page"];
}

- (void)syncPagesWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure loadMore:(BOOL)more {
	if (self.isSyncingPages) {
        WPLog(@"Already syncing pages. Skip");
        return;
    }
    self.isSyncingPages = YES;
    AFXMLRPCRequestOperation *operation = [self operationForPagesWithSuccess:success failure:failure loadMore:more];
    [self.api enqueueHTTPRequestOperation:operation];
}

- (void)syncCategoriesWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    AFXMLRPCRequestOperation *operation = [self operationForCategoriesWithSuccess:success failure:failure];
    [self.api enqueueHTTPRequestOperation:operation];
}

- (void)syncOptionsWithWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    AFXMLRPCRequestOperation *operation = [self operationForOptionsWithSuccess:success failure:failure];
    [self.api enqueueHTTPRequestOperation:operation];
}

- (NSString *)getOptionValue:(NSString *) name {
	if ( self.options == nil || (self.options.count == 0) ) {
        return nil;
    }
    NSDictionary *currentOption = [self.options objectForKey:name];
    
    return [currentOption objectForKey:@"value"];
}

- (void)syncCommentsWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
	if (self.isSyncingComments) {
        WPLog(@"Already syncing comments. Skip");
        return;
    }
    self.isSyncingComments = YES;
    AFXMLRPCRequestOperation *operation = [self operationForCommentsWithSuccess:success failure:failure];
    [self.api enqueueHTTPRequestOperation:operation];
}

- (void)syncPostFormatsWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    AFXMLRPCRequestOperation *operation = [self operationForPostFormatsWithSuccess:success failure:failure];
    [self.api enqueueHTTPRequestOperation:operation];
}

- (void)syncBlogWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    AFXMLRPCRequestOperation *operation;
    NSMutableArray *operations = [NSMutableArray arrayWithCapacity:6];
    operation = [self operationForOptionsWithSuccess:nil failure:nil];
    [operations addObject:operation];
    operation = [self operationForPostFormatsWithSuccess:nil failure:nil];
    [operations addObject:operation];
    operation = [self operationForCategoriesWithSuccess:nil failure:nil];
    [operations addObject:operation];
    operation = [self operationForCommentsWithSuccess:nil failure:nil];
    [operations addObject:operation];
    operation = [self operationForPostsWithSuccess:nil failure:nil loadMore:NO];
    [operations addObject:operation];
    operation = [self operationForPagesWithSuccess:nil failure:nil loadMore:NO];
    [operations addObject:operation];

    AFHTTPRequestOperation *combinedOperation = [self.api combinedHTTPRequestOperationWithOperations:operations success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
    [self.api enqueueHTTPRequestOperation:combinedOperation];
}

//generate md5 hash from string
- (NSString *) returnMD5Hash:(NSString*)concat {
    const char *concat_str = [concat UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(concat_str, strlen(concat_str), result);
    NSMutableString *hash = [NSMutableString string];
    for (int i = 0; i < 16; i++)
        [hash appendFormat:@"%02X", result[i]];
    return [hash lowercaseString];
	
}

#pragma mark - api accessor

- (AFXMLRPCClient *)api {
    if (_api == nil) {
        _api = [[AFXMLRPCClient alloc] initWithXMLRPCEndpoint:[NSURL URLWithString:self.xmlrpc]];
    }
    return _api;
}

#pragma mark - Private Methods

- (NSArray *)getXMLRPCArgsWithExtra:(id)extra {
    NSMutableArray *result = [NSMutableArray array];
    [result addObject:self.blogID];
    [result addObject:self.username];
    [result addObject:[self fetchPassword]];

    if ([extra isKindOfClass:[NSArray class]]) {
        [result addObjectsFromArray:extra];
    } else if (extra != nil) {
        [result addObject:extra];
    }

    return [NSArray arrayWithArray:result];
}

- (NSString *)fetchPassword {
    NSError *err;
	NSString *password;

	if (self.isWPcom) {
        password = [SFHFKeychainUtils getPasswordForUsername:self.username
                                              andServiceName:@"WordPress.com"
                                                       error:&err];

    } else {

		password = [SFHFKeychainUtils getPasswordForUsername:self.username
                                              andServiceName:self.hostURL
                                                       error:&err];
	}
	if (password == nil)
		password = @""; // FIXME: not good either, but prevents from crashing

	return password;
}

#pragma mark -

- (AFXMLRPCRequestOperation *)operationForOptionsWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    NSArray *parameters = [self getXMLRPCArgsWithExtra:nil];
    AFXMLRPCRequest *request = [self.api XMLRPCRequestWithMethod:@"wp.getOptions" parameters:parameters];
    AFXMLRPCRequestOperation *operation = [self.api XMLRPCRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([self isDeleted])
            return;

        self.options = [NSDictionary dictionaryWithDictionary:(NSDictionary *)responseObject];
        if (success) {
            success();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        WPFLog(@"Error syncing options: %@", [error localizedDescription]);

        if (failure) {
            failure(error);
        }
    }];

    return operation;
}

- (AFXMLRPCRequestOperation *)operationForPostFormatsWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    NSArray *parameters = [self getXMLRPCArgsWithExtra:nil];
    AFXMLRPCRequest *request = [self.api XMLRPCRequestWithMethod:@"wp.getPostFormats" parameters:parameters];
    AFXMLRPCRequestOperation *operation = [self.api XMLRPCRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([self isDeleted])
            return;

        self.postFormats = [NSDictionary dictionaryWithDictionary:(NSDictionary *)responseObject];
        if (success) {
            success();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        WPFLog(@"Error syncing post formats: %@", [error localizedDescription]);

        if (failure) {
            failure(error);
        }
    }];
    
    return operation;
}

- (AFXMLRPCRequestOperation *)operationForCommentsWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    NSDictionary *requestOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:100] forKey:@"number"];
    NSArray *parameters = [self getXMLRPCArgsWithExtra:requestOptions];
    AFXMLRPCRequest *request = [self.api XMLRPCRequestWithMethod:@"wp.getComments" parameters:parameters];
    AFXMLRPCRequestOperation *operation = [self.api XMLRPCRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([self isDeleted])
            return;

        [self mergeComments:responseObject];
        if (success) {
            success();
        }
        self.isSyncingComments = NO;
        self.lastCommentsSync = [NSDate date];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        WPFLog(@"Error syncing comments: %@", [error localizedDescription]);

        if (failure) {
            failure(error);
        }

        self.isSyncingComments = NO;
    }];
    
    return operation;
}

- (AFXMLRPCRequestOperation *)operationForCategoriesWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    NSArray *parameters = [self getXMLRPCArgsWithExtra:nil];
    AFXMLRPCRequest *request = [self.api XMLRPCRequestWithMethod:@"wp.getCategories" parameters:parameters];
    AFXMLRPCRequestOperation *operation = [self.api XMLRPCRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([self isDeleted])
            return;

        [self mergeCategories:responseObject];
        if (success) {
            success();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        WPFLog(@"Error syncing categories: %@", [error localizedDescription]);

        if (failure) {
            failure(error);
        }
    }];
    
    return operation;    
}

- (AFXMLRPCRequestOperation *)operationForPostsWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure loadMore:(BOOL)more {
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

    NSArray *parameters = [self getXMLRPCArgsWithExtra:[NSNumber numberWithInt:num]];
    AFXMLRPCRequest *request = [self.api XMLRPCRequestWithMethod:@"metaWeblog.getRecentPosts" parameters:parameters];
    AFXMLRPCRequestOperation *operation = [self.api XMLRPCRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([self isDeleted])
            return;
        
        NSArray *posts = (NSArray *)responseObject;

        // If we asked for more and we got what we had, there are no more posts to load
        if (more && ([posts count] <= [self.posts count])) {
            self.hasOlderPosts = [NSNumber numberWithBool:NO];
        } else if (!more) {
            //we should reset the flag otherwise when you refresh this blog you can't get more than 20 posts
            self.hasOlderPosts = [NSNumber numberWithBool:YES];
        }

        [self mergePosts:posts];
        if (success) {
            success();
        }

        self.lastPostsSync = [NSDate date];
        self.isSyncingPosts = NO;
        if (success) {
            success();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        WPFLog(@"Error syncing posts: %@", [error localizedDescription]);
        
        if (failure) {
            failure(error);
        }
        self.isSyncingPosts = NO;
    }];
    
    return operation;        
}

- (AFXMLRPCRequestOperation *)operationForPagesWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure loadMore:(BOOL)more {
    int num;
	
    int syncCount = [[self syncedPages] count];
    // Don't load more than 20 pages if we aren't at the end of the table,
    // even if they were previously donwloaded
    // 
    // Blogs with long history can get really slow really fast, 
    // with no chance to go back
    if (more) {
        num = MAX(syncCount, 20);
        if ([self.hasOlderPages boolValue]) {
            num += 20;
        }
    } else {
        num = 20;
    }

    NSArray *parameters = [self getXMLRPCArgsWithExtra:[NSNumber numberWithInt:num]];
    AFXMLRPCRequest *request = [self.api XMLRPCRequestWithMethod:@"wp.getPages" parameters:parameters];
    AFXMLRPCRequestOperation *operation = [self.api XMLRPCRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([self isDeleted])
            return;

        NSArray *pages = (NSArray *)responseObject;

        // If we asked for more and we got what we had, there are no more pages to load
        if (more && ([pages count] <= syncCount)) {
            self.hasOlderPages = [NSNumber numberWithBool:NO];
        } else if (!more) {
            //we should reset the flag otherwise when you refresh this blog you can't get more than 20 pages
            self.hasOlderPages = [NSNumber numberWithBool:YES];
        }

        [self mergePages:pages];
        if (success) {
            success();
        }

        self.lastPagesSync = [NSDate date];
        self.isSyncingPages = NO;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        WPFLog(@"Error syncing pages: %@", [error localizedDescription]);

        if (failure) {
            failure(error);
        }
        self.isSyncingPages = NO;
    }];

    return operation;
}

#pragma mark -

- (void)mergeCategories:(NSArray *)newCategories {
    // Don't even bother if blog has been deleted while fetching categories
    if ([self isDeleted])
        return;

	NSMutableArray *categoriesToKeep = [NSMutableArray array];
    for (NSDictionary *categoryInfo in newCategories) {
        Category *newCat = [Category createOrReplaceFromDictionary:categoryInfo forBlog:self];
        if (newCat != nil) {
            [categoriesToKeep addObject:newCat];
        } else {
            WPFLog(@"-[Category createOrReplaceFromDictionary:forBlog:] returned a nil category: %@", categoryInfo);
        }
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
}

- (void)mergePosts:(NSArray *)newPosts {
    // Don't even bother if blog has been deleted while fetching posts
    if ([self isDeleted])
        return;

    NSMutableArray *postsToKeep = [NSMutableArray array];
    for (NSDictionary *postInfo in newPosts) {
        Post *newPost = [Post createOrReplaceFromDictionary:postInfo forBlog:self];
        if (newPost != nil) {
            [postsToKeep addObject:newPost];
        } else {
            WPFLog(@"-[Post createOrReplaceFromDictionary:forBlog:] returned a nil post: %@", postInfo);
        }
    }

    NSArray *syncedPosts = [self syncedPosts];
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
					post.permaLink = nil;
				}
			} else {
				//post is not on the server anymore. delete it.
                WPLog(@"Deleting post: %@", post.postTitle);
                WPLog(@"%d posts left", [self.posts count]);
                [[self managedObjectContext] deleteObject:post];
            }
        }
    }

    [self dataSave];
}

- (void)mergePages:(NSArray *)newPages {
    if ([self isDeleted])
        return;

    NSMutableArray *pagesToKeep = [NSMutableArray array];
    for (NSDictionary *pageInfo in newPages) {
        Page *newPage = [Page createOrReplaceFromDictionary:pageInfo forBlog:self];
        if (newPage != nil) {
            [pagesToKeep addObject:newPage];
        } else {
            WPFLog(@"-[Page createOrReplaceFromDictionary:forBlog:] returned a nil page: %@", pageInfo);
        }
    }

    NSArray *syncedPages = [self syncedPages];
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
					page.permaLink = nil;
				}
			} else {
				//page is not on the server anymore. delete it.
                WPLog(@"Deleting page: %@", page);
                [[self managedObjectContext] deleteObject:page];
            }
        }
    }

    [self dataSave];
}

- (void)mergeComments:(NSArray *)newComments {
    // Don't even bother if blog has been deleted while fetching comments
    if ([self isDeleted])
        return;

	NSMutableArray *commentsToKeep = [NSMutableArray array];
    for (NSDictionary *commentInfo in newComments) {
        Comment *newComment = [Comment createOrReplaceFromDictionary:commentInfo forBlog:self];
        if (newComment != nil) {
            [commentsToKeep addObject:newComment];
        } else {
            WPFLog(@"-[Comment createOrReplaceFromDictionary:forBlog:] returned a nil comment: %@", commentInfo);
        }
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
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [_blavatarUrl release]; _blavatarUrl = nil;
    [_api release];
    [super dealloc];
}

@end
