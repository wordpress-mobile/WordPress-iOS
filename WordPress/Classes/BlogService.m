#import "BlogService.h"
#import "Blog.h"
#import "ContextManager.h"
#import "WPError.h"
#import "Comment.h"
#import "Page.h"
#import "CategoryService.h"

@interface BlogService ()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

NSString *const LastUsedBlogURLDefaultsKey = @"LastUsedBlogURLDefaultsKey";

@implementation BlogService

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context {
    self = [super init];
    if (self) {
        _managedObjectContext = context;
    }
    
    return self;
}

- (void)flagBlogAsLastUsed:(Blog *)blog {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:blog.url forKey:LastUsedBlogURLDefaultsKey];
    [defaults synchronize];
}

- (Blog *)lastUsedOrFirstBlog
{
    Blog *blog = [self lastUsedBlog];
    
    if (!blog) {
        blog = [self firstBlog];
    }
    
    return blog;
}

- (Blog *)lastUsedBlog
{
    // Try to get the last used blog, if there is one.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *url = [defaults stringForKey:LastUsedBlogURLDefaultsKey];
    if (!url) {
        // Check for the old key and migrate the value if it exists.
        // TODO: We can probably discard this in the 4.2 release.
        NSString *oldKey = @"EditPostViewControllerLastUsedBlogURL";
        url = [defaults stringForKey:oldKey];
        if (url) {
            [defaults setObject:url forKey:LastUsedBlogURLDefaultsKey];
            [defaults removeObjectForKey:oldKey];
            [defaults synchronize];
        }
    }
    
    if (!url) {
        return nil;
    }
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Blog"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"visible = YES AND url = %@", url];
    [fetchRequest setPredicate:predicate];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"blogName" ascending:YES]];
    NSError *error = nil;
    NSArray *results = [[[ContextManager sharedInstance] mainContext] executeFetchRequest:fetchRequest error:&error];
    if (error) {
        DDLogError(@"Couldn't fetch blogs: %@", error);
        return nil;
    }
    
    if([results count] == 0) {
        // Blog might have been removed from the app. Clear the key.
        [defaults removeObjectForKey:LastUsedBlogURLDefaultsKey];
        [defaults synchronize];
        return nil;
    }
    
    return [results firstObject];
}

- (Blog *)firstBlog
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"visible = YES"];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Blog"];
    [fetchRequest setPredicate:predicate];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"blogName" ascending:YES]];
    NSError *error = nil;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (error) {
        DDLogError(@"Couldn't fetch blogs: %@", error);
        return nil;
    }
    
    return [results firstObject];
}

- (void)syncPostsAndMetadataForBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    WPXMLRPCRequestOperation *operation;
    NSMutableArray *operations = [NSMutableArray arrayWithCapacity:4];
    operation = [self operationForOptionsWithBlog:blog success:nil failure:nil];
    [operations addObject:operation];
    operation = [self operationForPostFormatsWithBlog:blog success:nil failure:nil];
    [operations addObject:operation];
    operation = [self operationForCategoriesWithBlog:blog success:nil failure:nil];
    [operations addObject:operation];
    if (!blog.isSyncingPosts) {
        operation = [self operationForPostsWithBlog:blog success:success failure:failure loadMore:NO];
        [operations addObject:operation];
        blog.isSyncingPosts = YES;
    }
    
    AFHTTPRequestOperation *combinedOperation = [blog.api combinedHTTPRequestOperationWithOperations:operations success:nil failure:nil];
    [blog.api enqueueHTTPRequestOperation:combinedOperation];
}

- (void)syncPostsForBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure loadMore:(BOOL)more
{
    if (blog.isSyncingPosts) {
        DDLogWarn(@"Already syncing posts. Skip");
        return;
    }
    blog.isSyncingPosts = YES;
    
    WPXMLRPCRequestOperation *operation = [self operationForPostsWithBlog:blog success:success failure:failure loadMore:more];
    [blog.api enqueueXMLRPCRequestOperation:operation];
}

- (void)syncPagesForBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure loadMore:(BOOL)more
{
	if (blog.isSyncingPages) {
        DDLogWarn(@"Already syncing pages. Skip");
        return;
    }
    blog.isSyncingPages = YES;
    WPXMLRPCRequestOperation *operation = [self operationForPagesWithBlog:blog success:success failure:failure loadMore:more];
    [blog.api enqueueXMLRPCRequestOperation:operation];
}

- (void)syncCategoriesForBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    WPXMLRPCRequestOperation *operation = [self operationForCategoriesWithBlog:blog success:success failure:failure];
    [blog.api enqueueXMLRPCRequestOperation:operation];
}

- (void)syncOptionsForBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    WPXMLRPCRequestOperation *operation = [self operationForOptionsWithBlog:blog success:success failure:failure];
    [blog.api enqueueXMLRPCRequestOperation:operation];
}

- (void)syncCommentsForBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure
{
	if (blog.isSyncingComments) {
        DDLogWarn(@"Already syncing comments. Skip");
        return;
    }
    blog.isSyncingComments = YES;
    WPXMLRPCRequestOperation *operation = [self operationForCommentsWithBlog:blog success:success failure:failure];
    [blog.api enqueueXMLRPCRequestOperation:operation];
}

- (void)syncMediaLibraryForBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    if (blog.isSyncingMedia) {
        DDLogWarn(@"Already syncing media. Skip");
        return;
    }
    blog.isSyncingMedia = YES;
    WPXMLRPCRequestOperation *operation = [self operationForMediaLibraryWithBlog:blog success:success failure:failure];
    [blog.api enqueueXMLRPCRequestOperation:operation];
}

- (void)syncPostFormatsForBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    WPXMLRPCRequestOperation *operation = [self operationForPostFormatsWithBlog:blog success:success failure:failure];
    [blog.api enqueueXMLRPCRequestOperation:operation];
}

- (void)syncBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    WPXMLRPCRequestOperation *operation;
    NSMutableArray *operations = [NSMutableArray arrayWithCapacity:6];
    operation = [self operationForOptionsWithBlog:blog success:nil failure:nil];
    [operations addObject:operation];
    operation = [self operationForPostFormatsWithBlog:blog success:nil failure:nil];
    [operations addObject:operation];
    operation = [self operationForCategoriesWithBlog:blog success:nil failure:nil];
    [operations addObject:operation];
    
    if (!blog.isSyncingComments) {
        operation = [self operationForCommentsWithBlog:blog success:nil failure:nil];
        [operations addObject:operation];
        blog.isSyncingComments = YES;
    }
    
    if (!blog.isSyncingPosts) {
        operation = [self operationForPostsWithBlog:blog success:nil failure:nil loadMore:NO];
        [operations addObject:operation];
        blog.isSyncingPosts = YES;
    }
    
    if (!blog.isSyncingPages) {
        operation = [self operationForPagesWithBlog:blog success:nil failure:nil loadMore:NO];
        [operations addObject:operation];
        blog.isSyncingPages = YES;
    }
    
    if (!blog.isSyncingMedia) {
        operation = [self operationForMediaLibraryWithBlog:blog success:nil failure:nil];
        [operations addObject:operation];
        blog.isSyncingMedia = YES;
    }
    
    AFHTTPRequestOperation *combinedOperation = [blog.api combinedHTTPRequestOperationWithOperations:operations success:^(AFHTTPRequestOperation *operation, id responseObject) {
        DDLogVerbose(@"syncBlogWithSuccess:failure: completed successfully.");
        if (success) {
            success();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogError(@"syncBlogWithSuccess:failure: encountered an error: %@", error);
        if (failure) {
            failure(error);
        }
    }];
    
    [blog.api enqueueHTTPRequestOperation:combinedOperation];
}

- (void)checkVideoPressEnabledForBlog:(Blog *)blog success:(void (^)(BOOL enabled))success failure:(void (^)(NSError *error))failure
{
    if (!blog.isWPcom) {
        if (success) success(YES);
        return;
    }
    NSArray *parameters = [blog getXMLRPCArgsWithExtra:nil];
    WPXMLRPCRequest *request = [blog.api XMLRPCRequestWithMethod:@"wpcom.getFeatures" parameters:parameters];
    WPXMLRPCRequestOperation *operation = [blog.api XMLRPCRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        BOOL videoEnabled = YES;
        if(([responseObject isKindOfClass:[NSDictionary class]]) && ([responseObject objectForKey:@"videopress_enabled"] != nil)) {
            videoEnabled = [[responseObject objectForKey:@"videopress_enabled"] boolValue];
        } else {
            videoEnabled = YES;
        }
        
        if (success) {
            success(videoEnabled);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogError(@"Error while checking if VideoPress is enabled: %@", error);
        
        if (failure) {
            failure(error);
        }
    }];
    [blog.api enqueueXMLRPCRequestOperation:operation];
}

- (NSInteger)blogCountForAllAccounts
{
    return [self blogCountWithPredicate:nil];
}

- (NSInteger)blogCountSelfHosted
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"account.isWpcom = %@" argumentArray:@[@(NO)]];
    return [self blogCountWithPredicate:predicate];
}

- (NSInteger)blogCountVisibleForAllAccounts
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"visible = %@" argumentArray:@[@(YES)]];
    return [self blogCountWithPredicate:predicate];
}

#pragma mark - Private methods

- (NSInteger)blogCountWithPredicate:(NSPredicate *)predicate
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Blog" inManagedObjectContext:self.managedObjectContext]];
    [request setIncludesSubentities:NO];
    
    if (predicate) {
        [request setPredicate:predicate];
    }
    
    NSError *err;
    NSUInteger count = [self.managedObjectContext countForFetchRequest:request error:&err];
    if(count == NSNotFound) {
        count = 0;
    }
    return count;
}

- (WPXMLRPCRequestOperation *)operationForOptionsWithBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure {
    __block WPXMLRPCRequestOperation *operation;
    [self.managedObjectContext performBlockAndWait:^{
        NSArray *parameters = [blog getXMLRPCArgsWithExtra:nil];
        WPXMLRPCRequest *request = [blog.api XMLRPCRequestWithMethod:@"wp.getOptions" parameters:parameters];
        operation = [blog.api XMLRPCRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if ([blog isDeleted] || blog.managedObjectContext == nil)
                return;
            
            blog.options = [NSDictionary dictionaryWithDictionary:(NSDictionary *)responseObject];
            NSString *minimumVersion = @"3.6";
            float version = [[blog version] floatValue];
            if (version < [minimumVersion floatValue]) {
                if (blog.lastUpdateWarning == nil || [blog.lastUpdateWarning floatValue] < [minimumVersion floatValue]) {
                    [WPError showAlertWithTitle:NSLocalizedString(@"WordPress version too old", @"")
                                        message:[NSString stringWithFormat:NSLocalizedString(@"The site at %@ uses WordPress %@. We recommend to update to the latest version, or at least %@", @""), [blog hostname], [blog version], minimumVersion]];
                    blog.lastUpdateWarning = minimumVersion;
                }
            }
            if (success) {
                success();
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            DDLogError(@"Error syncing options: %@", error);
            
            if (failure) {
                failure(error);
            }
        }];
    }];
    return operation;
}

- (WPXMLRPCRequestOperation *)operationForPostFormatsWithBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure {
    __block WPXMLRPCRequestOperation *operation;
    [self.managedObjectContext performBlockAndWait:^{
        NSDictionary *dict = [NSDictionary dictionaryWithObject:@"1" forKey:@"show-supported"];
        NSArray *parameters = [blog getXMLRPCArgsWithExtra:dict];
        
        WPXMLRPCRequest *request = [blog.api XMLRPCRequestWithMethod:@"wp.getPostFormats" parameters:parameters];
        operation = [blog.api XMLRPCRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if ([blog isDeleted] || blog.managedObjectContext == nil)
                return;
            
            NSDictionary *respDict = [NSDictionary dictionaryWithDictionary:(NSDictionary *)responseObject];
            if ([respDict objectForKey:@"supported"] && [[respDict objectForKey:@"supported"] isKindOfClass:[NSArray class]]) {
                NSMutableArray *supportedKeys = [NSMutableArray arrayWithArray:[respDict objectForKey:@"supported"]];
                // Standard isn't included in the list of supported formats? Maybe it will be one day?
                if (![supportedKeys containsObject:@"standard"]) {
                    [supportedKeys addObject:@"standard"];
                }
                
                NSDictionary *allFormats = [respDict objectForKey:@"all"];
                NSMutableArray *supportedValues = [NSMutableArray array];
                for (NSString *key in supportedKeys) {
                    [supportedValues addObject:[allFormats objectForKey:key]];
                }
                respDict = [NSDictionary dictionaryWithObjects:supportedValues forKeys:supportedKeys];
            }
            blog.postFormats = respDict;
            if (success) {
                success();
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
	        DDLogError(@"Error syncing post formats (%@): %@", operation.request.URL, error);
            
            if (failure) {
                failure(error);
            }
        }];
    }];
    return operation;
}

- (WPXMLRPCRequestOperation *)operationForCommentsWithBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure {
    __block WPXMLRPCRequestOperation *operation;
    [self.managedObjectContext performBlockAndWait:^{
        NSDictionary *requestOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:100] forKey:@"number"];
        NSArray *parameters = [blog getXMLRPCArgsWithExtra:requestOptions];
        WPXMLRPCRequest *request = [blog.api XMLRPCRequestWithMethod:@"wp.getComments" parameters:parameters];
        operation = [blog.api XMLRPCRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if ([blog isDeleted] || blog.managedObjectContext == nil)
                return;
            
            [Comment mergeNewComments:responseObject forBlog:blog];
            blog.isSyncingComments = NO;
            blog.lastCommentsSync = [NSDate date];
            
            if (success) {
                success();
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
	        DDLogError(@"Error syncing comments (%@): %@", operation.request.URL, error);
            blog.isSyncingComments = NO;
            
            if (failure) {
                failure(error);
            }
        }];
    }];
    return operation;
}

- (WPXMLRPCRequestOperation *)operationForCategoriesWithBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure {
    __block WPXMLRPCRequestOperation *operation;
    [self.managedObjectContext performBlockAndWait:^{
        NSArray *parameters = [blog getXMLRPCArgsWithExtra:nil];
        WPXMLRPCRequest *request = [blog.api XMLRPCRequestWithMethod:@"wp.getCategories" parameters:parameters];
        operation = [blog.api XMLRPCRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if ([blog isDeleted] || blog.managedObjectContext == nil)
                return;
            
            CategoryService *categoryService = [[CategoryService alloc] initWithManagedObjectContext:self.managedObjectContext];
            [categoryService mergeNewCategories:responseObject forBlogObjectID:blog.objectID];
            
            if (success) {
                success();
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
	        DDLogError(@"Error syncing categories (%@): %@", operation.request.URL, error);
            
            if (failure) {
                failure(error);
            }
        }];
    }];
    return operation;
}

- (WPXMLRPCRequestOperation *)operationForPostsWithBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure loadMore:(BOOL)more {
    // Don't load more than 20 posts if we aren't at the end of the table,
    // even if they were previously donwloaded
    //
    // Blogs with long history can get really slow really fast,
    // with no chance to go back
    
    NSUInteger postBatchSize = 40;
    __block WPXMLRPCRequestOperation *operation;
    [self.managedObjectContext performBlockAndWait:^{
        NSUInteger postsToRequest = postBatchSize;
        if (more) {
            postsToRequest = MAX([blog.posts count], postBatchSize);
            if ([blog.hasOlderPosts boolValue]) {
                postsToRequest += postBatchSize;
            }
        }
        
        NSArray *parameters = [blog getXMLRPCArgsWithExtra:[NSNumber numberWithUnsignedInteger:postsToRequest]];
        WPXMLRPCRequest *request = [blog.api XMLRPCRequestWithMethod:@"metaWeblog.getRecentPosts" parameters:parameters];
        operation = [blog.api XMLRPCRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if ([blog isDeleted] || blog.managedObjectContext == nil)
                return;
            
            NSArray *posts = (NSArray *)responseObject;
            
            // If we asked for more and we got what we had, there are no more posts to load
            if (more && ([posts count] <= [blog.posts count])) {
                blog.hasOlderPosts = [NSNumber numberWithBool:NO];
            } else if (!more) {
                //we should reset the flag otherwise when you refresh this blog you can't get more than 20 posts
                blog.hasOlderPosts = [NSNumber numberWithBool:YES];
            }
            
            [Post mergeNewPosts:responseObject forBlog:blog];
            
            blog.lastPostsSync = [NSDate date];
            blog.isSyncingPosts = NO;
            
            if (success) {
                success();
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
	        DDLogError(@"Error syncing posts (%@): %@", operation.request.URL, error);
            blog.isSyncingPosts = NO;
            
            if (failure) {
                failure(error);
            }
        }];
    }];
    return operation;
}

- (WPXMLRPCRequestOperation *)operationForPagesWithBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure loadMore:(BOOL)more {
    // Don't load more than 20 pages if we aren't at the end of the table,
    // even if they were previously donwloaded
    //
    // Blogs with long history can get really slow really fast,
    // with no chance to go back
    
    NSUInteger pageBatchSize = 40;
    __block WPXMLRPCRequestOperation *operation;
    [self.managedObjectContext performBlockAndWait:^{
        NSUInteger pagesToRequest = pageBatchSize;
        NSUInteger syncCount = [self countForSyncedPostsWithEntityName:@"Page"];
        if (more) {
            pagesToRequest = MAX(syncCount, pageBatchSize);
            if ([blog.hasOlderPages boolValue]) {
                pagesToRequest += pageBatchSize;
            }
        }
        
        NSArray *parameters = [blog getXMLRPCArgsWithExtra:[NSNumber numberWithUnsignedInteger:pagesToRequest]];
        WPXMLRPCRequest *request = [blog.api XMLRPCRequestWithMethod:@"wp.getPages" parameters:parameters];
        operation = [blog.api XMLRPCRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if ([blog isDeleted] || blog.managedObjectContext == nil)
                return;
            
            NSArray *pages = (NSArray *)responseObject;
            
            // If we asked for more and we got what we had, there are no more pages to load
            if (more && ([pages count] <= syncCount)) {
                blog.hasOlderPages = [NSNumber numberWithBool:NO];
            } else if (!more) {
                //we should reset the flag otherwise when you refresh this blog you can't get more than 20 pages
                blog.hasOlderPages = [NSNumber numberWithBool:YES];
            }
            
            [Page mergeNewPosts:responseObject forBlog:blog];
            blog.lastPagesSync = [NSDate date];
            blog.isSyncingPages = NO;
            if (success) {
                success();
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
	        DDLogError(@"Error syncing pages (%@): %@", operation.request.URL, error);
            blog.isSyncingPages = NO;
            
            if (failure) {
                failure(error);
            }
        }];
    }];
    return operation;
}


- (WPXMLRPCRequestOperation *)operationForMediaLibraryWithBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *))failure {
    WPXMLRPCRequest *mediaLibraryRequest = [blog.api XMLRPCRequestWithMethod:@"wp.getMediaLibrary" parameters:[blog getXMLRPCArgsWithExtra:nil]];
    WPXMLRPCRequestOperation *operation = [blog.api XMLRPCRequestOperationWithRequest:mediaLibraryRequest success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [Media mergeNewMedia:responseObject forBlog:blog];
        blog.isSyncingMedia = NO;
        if (success) {
            success();
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogError(@"Error syncing media library: %@", [error localizedDescription]);
        blog.isSyncingMedia = NO;
        
        if (failure) {
            failure(error);
        }
    }];
    return operation;
}

- (NSUInteger)countForSyncedPostsWithEntityName:(NSString *)entityName {
    __block NSUInteger count = 0;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(remoteStatusNumber == %@) AND (postID != NULL) AND (original == NULL) AND (blog == %@)",
                              [NSNumber numberWithInt:AbstractPostRemoteStatusSync], self];
    [request setPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date_created_gmt" ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    request.includesSubentities = NO;
    request.resultType = NSCountResultType;
    
    [self.managedObjectContext performBlockAndWait:^{
        NSError *error = nil;
        count = [self.managedObjectContext countForFetchRequest:request error:&error];
    }];
    return count;
}


@end
