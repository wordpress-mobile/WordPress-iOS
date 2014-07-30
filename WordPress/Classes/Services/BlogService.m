#import "BlogService.h"
#import "Blog.h"
#import "ContextManager.h"
#import "WPError.h"
#import "Comment.h"
#import "Page.h"
#import "CategoryService.h"
#import "CommentService.h"
#import "BlogServiceRemote.h"
#import "BlogServiceRemoteXMLRPC.h"
#import "BlogServiceRemoteREST.h"
#import "BlogServiceRemoteProxy.h"


@interface BlogService ()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

NSString *const LastUsedBlogURLDefaultsKey = @"LastUsedBlogURLDefaultsKey";



@implementation BlogService

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context
{
    self = [super init];
    if (self) {
        _managedObjectContext = context;
    }
    
    return self;
}

- (Blog *)blogByBlogId:(NSNumber *)blogID
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Blog"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"blogID == %@", blogID];
    
    fetchRequest.predicate = predicate;
    
    NSError *error = nil;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (error) {
        DDLogError(@"Error while fetching Blog by blogID: %@", error);
        return nil;
    }
    
    return [results firstObject];
}

- (Blog *)blogByBlogName:(NSString *)blogName
{
    if (!blogName) {
        return nil;
    }
    
    NSPredicate *subjectPredicate       = [NSPredicate predicateWithFormat:@"self.blogName CONTAINS[cd] %@", blogName];
    NSPredicate *wpcomPredicate         = [NSPredicate predicateWithFormat:@"self.account.isWpcom == YES"];
    NSPredicate *jetpackPredicate       = [NSPredicate predicateWithFormat:@"self.jetpackAccount != nil"];
    NSPredicate *statsBlogsPredicate    = [NSCompoundPredicate orPredicateWithSubpredicates:@[wpcomPredicate, jetpackPredicate]];
    NSPredicate *combinedPredicate      = [NSCompoundPredicate andPredicateWithSubpredicates:@[subjectPredicate, statsBlogsPredicate]];
    
    NSFetchRequest *fetchRequest        = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Blog class])];
    fetchRequest.predicate              = combinedPredicate;
    
    NSError *error = nil;
    NSArray *blogs = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (error) {
        DDLogError(@"Error while retrieving blog named %d: %@", blogName, error);
        return nil;
    }
    
    return [blogs firstObject];
}

- (void)flagBlogAsLastUsed:(Blog *)blog
{
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

- (Blog *)lastUsedOrFirstWPcomBlog
{
    Blog *blog = [self lastUsedBlog];

    if (![blog isWPcom]) {
        blog = [self firstWPComBlog];
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
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
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

- (Blog *)firstWPComBlog
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"account.isWpcom = YES AND visible = YES"];
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
    id<BlogServiceRemote> remote = [self remoteForBlog:blog];
    [remote syncPostsAndMetadataForBlog:blog
                      categoriesSuccess:[self categoriesHandlerWithBlog:blog completionHandler:nil]
                         optionsSuccess:[self optionsHandlerWithBlog:blog completionHandler:nil]
                     postFormatsSuccess:[self postFormatsHandlerWithBlog:blog completionHandler:nil]
                           postsSuccess:[self postsHandlerWithBlog:blog loadMore:NO completionHandler:nil]
                         overallSuccess:^{
                             [self.managedObjectContext performBlockAndWait:^{
                                 [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
                             }];
                             
                             if (success) {
                                 success();
                             }
                         }
                                failure:^(NSError *error) {
                                    blog.isSyncingMedia = NO;
                                    blog.isSyncingPages = NO;
                                    blog.isSyncingPosts = NO;
                                    
                                    if (failure) {
                                        failure(error);
                                    }
                                }];
}

- (void)syncPostsForBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure loadMore:(BOOL)more
{
    if (blog.isSyncingPosts) {
        DDLogWarn(@"Already syncing posts. Skip");
        return;
    }
    blog.isSyncingPosts = YES;
    
    // TODO :: Push batch size into remote since it's not a local constraint and could be remote implementation dependent
    NSUInteger postBatchSize = 40;
    NSUInteger postsToRequest = postBatchSize;
    if (more) {
        postsToRequest = MAX([blog.posts count], postBatchSize);
        if ([blog.hasOlderPosts boolValue]) {
            postsToRequest += postBatchSize;
        }
    }
    
    id<BlogServiceRemote> remote = [self remoteForBlog:blog];
    [remote syncPostsForBlog:blog
                   batchSize:postsToRequest
                    loadMore:more
                     success:[self postsHandlerWithBlog:blog loadMore:more completionHandler:success]
                     failure:^(NSError *error) {
                         blog.isSyncingPosts = NO;
                         
                         if (failure) {
                             failure(error);
                         }
                     }];
}

- (void)syncPagesForBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure loadMore:(BOOL)more
{
	if (blog.isSyncingPages) {
        DDLogWarn(@"Already syncing pages. Skip");
        return;
    }
    blog.isSyncingPages = YES;
    
    // TODO :: Push batch size into remote since it's not a local constraint and could be remote implementation dependent
    NSUInteger pageBatchSize = 40;
    NSUInteger pagesToRequest = pageBatchSize;
    NSUInteger syncCount = [self countForSyncedPostsWithEntityName:@"Page" forBlog:blog];
    if (more) {
        pagesToRequest = MAX(syncCount, pageBatchSize);
        if ([blog.hasOlderPages boolValue]) {
            pagesToRequest += pageBatchSize;
        }
    }
    
    id<BlogServiceRemote> remote = [self remoteForBlog:blog];
    [remote syncPagesForBlog:blog
                   batchSize:pagesToRequest
                    loadMore:more
                     success:[self pagesHandlerWithBlog:blog loadMore:more syncCount:syncCount completionHandler:success]
                     failure:^(NSError *error) {
                         blog.isSyncingPages = NO;
                         
                         if (failure) {
                             failure(error);
                         }
                     }];
}

- (void)syncCategoriesForBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    id<BlogServiceRemote> remote = [self remoteForBlog:blog];
    [remote syncCategoriesForBlog:blog success:[self categoriesHandlerWithBlog:blog completionHandler:success] failure:failure];
}

- (void)syncOptionsForBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    id<BlogServiceRemote> remote = [self remoteForBlog:blog];
    [remote syncOptionsForBlog:blog success:[self optionsHandlerWithBlog:blog completionHandler:success] failure:failure];
}

- (void)syncMediaLibraryForBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    if (blog.isSyncingMedia) {
        DDLogWarn(@"Already syncing media. Skip");
        return;
    }
    blog.isSyncingMedia = YES;
    
    id<BlogServiceRemote> remote = [self remoteForBlog:blog];
    [remote syncMediaLibraryForBlog:blog
                            success:[self mediaHandlerWithBlog:blog completionHandler:success]
                            failure:^(NSError *error) {
                                blog.isSyncingMedia = NO;
                                
                                if (failure) {
                                    failure(error);
                                }
                            }];
}

- (void)syncPostFormatsForBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    id<BlogServiceRemote> remote = [self remoteForBlog:blog];
    [remote syncPostFormatsForBlog:blog success:[self postFormatsHandlerWithBlog:blog completionHandler:success] failure:failure];
}

- (void)syncBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    id<BlogServiceRemote> remote = [self remoteForBlog:blog];
    [remote syncBlogContentAndMetadata:blog
                     categoriesSuccess:[self categoriesHandlerWithBlog:blog completionHandler:nil]
                          mediaSuccess:[self mediaHandlerWithBlog:blog completionHandler:nil]
                        optionsSuccess:[self optionsHandlerWithBlog:blog completionHandler:nil]
                          pagesSuccess:[self pagesHandlerWithBlog:blog loadMore:NO syncCount:0 completionHandler:nil]
                    postFormatsSuccess:[self postFormatsHandlerWithBlog:blog completionHandler:nil]
                          postsSuccess:[self postsHandlerWithBlog:blog loadMore:NO completionHandler:nil]
                        overallSuccess:^{
                            [self.managedObjectContext performBlockAndWait:^{
                                [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
                            }];

                            if (success) {
                                success();
                            }
                        }
                               failure:^(NSError *error) {
                                   blog.isSyncingMedia = NO;
                                   blog.isSyncingPages = NO;
                                   blog.isSyncingPosts = NO;
                                   
                                   if (failure) {
                                       failure(error);
                                   }
                               }];

    CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:self.managedObjectContext];
    // Right now, none of the callers care about the results of the sync
    // We're ignoring the callbacks here but this needs refactoring
    [commentService syncCommentsForBlog:blog success:nil failure:nil];
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

- (NSArray *)blogsForAllAccounts
{
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"blogName" ascending:YES];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Blog" inManagedObjectContext:self.managedObjectContext]];
    [request setSortDescriptors:@[sortDescriptor]];
    
    NSError *error;
    NSArray *blogs = [self.managedObjectContext executeFetchRequest:request error:&error];

    if (error) {
        DDLogError(@"Error while retrieving all blogs");
        return nil;
    }
    
    return blogs;
}

#pragma mark - Private methods

- (id<BlogServiceRemote>)remoteForBlog:(Blog *)blog {
    BlogServiceRemoteXMLRPC *xmlrpcRemote = [[BlogServiceRemoteXMLRPC alloc] initWithApi:blog.api];
    BlogServiceRemoteREST *restRemote = nil;
    if (blog.restApi) {
        restRemote = [[BlogServiceRemoteREST alloc] initWithApi:blog.restApi];
    }
    id<BlogServiceRemote> remote = [[BlogServiceRemoteProxy alloc] initWithXMLRPCRemote:xmlrpcRemote RESTRemote:restRemote];

    return remote;
}

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

- (NSUInteger)countForSyncedPostsWithEntityName:(NSString *)entityName forBlog:(Blog *)blog {
    __block NSUInteger count = 0;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(remoteStatusNumber == %@) AND (postID != NULL) AND (original == NULL) AND (blog == %@)",
                              [NSNumber numberWithInt:AbstractPostRemoteStatusSync], blog];
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

#pragma mark - Completion handlers

- (CategoriesHandler)categoriesHandlerWithBlog:(Blog *)blog completionHandler:(void (^)(void))completion
{
    return ^void(NSArray *categories) {
        if ([blog isDeleted] || blog.managedObjectContext == nil)
            return;
        
        [self.managedObjectContext performBlockAndWait:^{
            CategoryService *categoryService = [[CategoryService alloc] initWithManagedObjectContext:self.managedObjectContext];
            [categoryService mergeNewCategories:categories forBlogObjectID:blog.objectID];
        }];

        if (completion) {
            completion();
        }
    };
}

- (MediaHandler)mediaHandlerWithBlog:(Blog *)blog completionHandler:(void (^)(void))completion
{
    return ^void(NSArray *media) {
        [Media mergeNewMedia:media forBlog:blog];
        blog.isSyncingMedia = NO;
        
        if (completion) {
            completion();
        }
    };
}

- (OptionsHandler)optionsHandlerWithBlog:(Blog *)blog completionHandler:(void (^)(void))completion
{
    return ^void(NSDictionary *options) {
        if ([blog isDeleted] || blog.managedObjectContext == nil)
            return;
        
        blog.options = [NSDictionary dictionaryWithDictionary:options];
        NSString *minimumVersion = @"3.6";
        float version = [[blog version] floatValue];
        if (version < [minimumVersion floatValue]) {
            if (blog.lastUpdateWarning == nil || [blog.lastUpdateWarning floatValue] < [minimumVersion floatValue]) {
                // TODO :: Remove UI call from service layer
                [WPError showAlertWithTitle:NSLocalizedString(@"WordPress version too old", @"")
                                    message:[NSString stringWithFormat:NSLocalizedString(@"The site at %@ uses WordPress %@. We recommend to update to the latest version, or at least %@", @""), [blog hostname], [blog version], minimumVersion]];
                blog.lastUpdateWarning = minimumVersion;
            }
        }
        
        [self.managedObjectContext performBlockAndWait:^{
            [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
        }];

        if (completion) {
            completion();
        }
    };
}

- (PagesHandler)pagesHandlerWithBlog:(Blog *)blog loadMore:(BOOL)more syncCount:(NSUInteger)syncCount completionHandler:(void (^)(void))completion
{
    return ^void(NSArray *pages) {
        if ([blog isDeleted] || blog.managedObjectContext == nil)
            return;
        
        // If we asked for more and we got what we had, there are no more pages to load
        if (more && ([pages count] <= syncCount)) {
            blog.hasOlderPages = [NSNumber numberWithBool:NO];
        } else if (!more) {
            //we should reset the flag otherwise when you refresh this blog you can't get more than 20 pages
            blog.hasOlderPages = [NSNumber numberWithBool:YES];
        }
        
        [Page mergeNewPosts:pages forBlog:blog];
        blog.lastPagesSync = [NSDate date];
        blog.isSyncingPages = NO;
        
        if (completion) {
            completion();
        }
    };
}

- (PostFormatsHandler)postFormatsHandlerWithBlog:(Blog *)blog completionHandler:(void (^)(void))completion
{
    return ^void(NSDictionary *postFormats) {
        if ([blog isDeleted] || blog.managedObjectContext == nil)
            return;
        
        NSDictionary *respDict = postFormats;
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

        if (completion) {
            completion();
        }
    };
}

- (PostsHandler)postsHandlerWithBlog:(Blog *)blog loadMore:(BOOL)more completionHandler:(void (^)(void))completion
{
    return ^void(NSArray *posts) {
        if ([blog isDeleted] || blog.managedObjectContext == nil)
            return;
        
        // If we asked for more and we got what we had, there are no more posts to load
        if (more && ([posts count] <= [blog.posts count])) {
            blog.hasOlderPosts = [NSNumber numberWithBool:NO];
        } else if (!more) {
            //we should reset the flag otherwise when you refresh this blog you can't get more than 20 posts
            blog.hasOlderPosts = [NSNumber numberWithBool:YES];
        }
        
        [Post mergeNewPosts:posts forBlog:blog];
        
        blog.lastPostsSync = [NSDate date];
        blog.isSyncingPosts = NO;
        
        if (completion) {
            completion();
        }
    };
}

- (NSTimeZone *)timeZoneForBlog:(Blog *)blog
{
    NSString *timeZoneName = [blog.options stringForKey:@"timezone"];
    NSNumber *gmtOffSet = [blog.options numberForKey:@"gmt_offset"];
    id optionValue = [blog getOptionValue:@"time_zone"];
    
    NSTimeZone *timeZone = nil;
    if (timeZoneName.length > 0) {
        timeZone = [NSTimeZone timeZoneWithName:timeZoneName];
    }
    
    if (!timeZone && gmtOffSet != nil) {
        timeZone = [NSTimeZone timeZoneForSecondsFromGMT:(gmtOffSet.floatValue * 60.0 * 60.0)];
    }
    
    if (!timeZone && optionValue != nil) {
        NSInteger timeZoneOffsetSeconds = [optionValue floatValue] * 60.0 * 60.0;
        timeZone = [NSTimeZone timeZoneForSecondsFromGMT:timeZoneOffsetSeconds];
    }
    
    return timeZone;
}

@end
