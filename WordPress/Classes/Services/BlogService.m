#import "BlogService.h"
#import "Blog.h"
#import "WPAccount.h"
#import "AccountService.h"
#import "ContextManager.h"
#import "WPError.h"
#import "Comment.h"
#import "Post.h"
#import "Page.h"
#import "Media.h"
#import "PostCategoryService.h"
#import "CommentService.h"
#import "PostService.h"
#import "BlogServiceRemote.h"
#import "BlogServiceRemoteXMLRPC.h"
#import "BlogServiceRemoteREST.h"
#import "AccountServiceRemote.h"
#import "AccountServiceRemoteREST.h"
#import "AccountServiceRemoteXMLRPC.h"
#import "RemoteBlog.h"
#import "NSString+XMLExtensions.h"
#import "TodayExtensionService.h"

NSString *const LastUsedBlogURLDefaultsKey = @"LastUsedBlogURLDefaultsKey";
NSString *const EditPostViewControllerLastUsedBlogURLOldKey = @"EditPostViewControllerLastUsedBlogURL";
NSString *const WPComGetFeatures = @"wpcom.getFeatures";
NSString *const VideopressEnabled = @"videopress_enabled";
NSString *const MinimumVersion = @"3.6";
NSString *const HttpsPrefix = @"https://";
CGFloat const OneHourInSeconds = 60.0 * 60.0;

@interface BlogService ()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

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
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"blogID == %@", blogID];
    return [self blogWithPredicate:predicate];
}

- (void)flagBlogAsLastUsed:(Blog *)blog
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:blog.url
                 forKey:LastUsedBlogURLDefaultsKey];
    [defaults synchronize];
}

- (Blog *)lastUsedOrFirstBlog
{
    Blog *blog = [self lastUsedOrPrimaryBlog];

    if (!blog) {
        blog = [self firstBlog];
    }

    return blog;
}

- (Blog *)lastUsedOrFirstBlogThatSupports:(BlogFeature)feature
{
    Blog *blog = [self lastUsedOrPrimaryBlog];

    if (![blog supports:feature]) {
        blog = [self firstBlogThatSupports:feature];
    }

    return blog;
}

- (Blog *)lastUsedOrPrimaryBlog
{
    Blog *blog = [self lastUsedBlog];

    if (!blog) {
        blog = [self primaryBlog];
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
        NSString *oldKey = EditPostViewControllerLastUsedBlogURLOldKey;
        url = [defaults stringForKey:oldKey];
        if (url) {
            [defaults setObject:url
                         forKey:LastUsedBlogURLDefaultsKey];
            [defaults removeObjectForKey:oldKey];
            [defaults synchronize];
        }
    }

    if (!url) {
        return nil;
    }

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"visible = YES AND url = %@", url];
    Blog *blog = [self blogWithPredicate:predicate];

    if (!blog) {
        // Blog might have been removed from the app. Clear the key.
        [defaults removeObjectForKey:LastUsedBlogURLDefaultsKey];
        [defaults synchronize];
    }

    return blog;
}

- (Blog *)primaryBlog
{
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:self.managedObjectContext];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    return defaultAccount.defaultBlog;
}

- (Blog *)firstBlogThatSupports:(BlogFeature)feature
{
    NSPredicate *predicate = [self predicateForVisibleBlogs];
    NSArray *results = [self blogsWithPredicate:predicate];

    for (Blog *blog in results) {
        if ([blog supports:feature]) {
            return blog;
        }
    }
    return nil;
}

- (Blog *)firstBlog
{
    NSPredicate *predicate = [self predicateForVisibleBlogs];
    return [self blogWithPredicate:predicate];
}

- (void)syncBlogsForAccount:(WPAccount *)account
                    success:(void (^)())success
                    failure:(void (^)(NSError *error))failure
{
    DDLogMethod();

    id<AccountServiceRemote> remote = [self remoteForAccount:account];
    [remote getBlogsWithSuccess:^(NSArray *blogs) {
        [self.managedObjectContext performBlock:^{
            [self mergeBlogs:blogs
                 withAccount:account
                  completion:success];
            
            Blog *defaultBlog = account.defaultBlog;
            TodayExtensionService *service = [TodayExtensionService new];
            BOOL widgetIsConfigured = [service widgetIsConfigured];
            
            if (WIDGETS_EXIST
                && !widgetIsConfigured
                && defaultBlog != nil
                && account.isWpcom) {
                NSNumber *siteId = defaultBlog.blogID;
                NSString *blogName = defaultBlog.blogName;
                NSTimeZone *timeZone = [self timeZoneForBlog:defaultBlog];
                NSString *oauth2Token = account.authToken;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    TodayExtensionService *service = [TodayExtensionService new];
                    [service configureTodayWidgetWithSiteID:siteId
                                                   blogName:blogName
                                               siteTimeZone:timeZone
                                             andOAuth2Token:oauth2Token];
                });
            }
        }];
    } failure:^(NSError *error) {
        DDLogError(@"Error syncing blogs: %@", error);

        if (failure) {
            failure(error);
        }
    }];
}

- (void)syncOptionsForBlog:(Blog *)blog
                   success:(void (^)())success
                   failure:(void (^)(NSError *error))failure
{
    id<BlogServiceRemote> remote = [self remoteForBlog:blog];
    [remote syncOptionsForBlog:blog
                       success:[self optionsHandlerWithBlogObjectID:blog.objectID
                                                  completionHandler:success]
                       failure:failure];
}

- (void)syncPostFormatsForBlog:(Blog *)blog
                       success:(void (^)())success
                       failure:(void (^)(NSError *error))failure
{
    id<BlogServiceRemote> remote = [self remoteForBlog:blog];
    [remote syncPostFormatsForBlog:blog
                           success:[self postFormatsHandlerWithBlogObjectID:blog.objectID
                                                          completionHandler:success]
                           failure:failure];
}

- (void)syncBlog:(Blog *)blog
         success:(void (^)())success
         failure:(void (^)(NSError *error))failure
{
    if ([self shouldStaggerRequestsForBlog:blog]) {
        [self syncBlogStaggeringRequests:blog];
        return;
    }
    NSManagedObjectID *blogObjectID = blog.objectID;
    id<BlogServiceRemote> remote = [self remoteForBlog:blog];
    [remote syncOptionsForBlog:blog success:[self optionsHandlerWithBlogObjectID:blogObjectID
                                                               completionHandler:nil]
                       failure:^(NSError *error) { DDLogError(@"Failed syncing options for blog %@: %@", blog.url, error); }];
    
    [remote syncPostFormatsForBlog:blog
                           success:[self postFormatsHandlerWithBlogObjectID:blogObjectID
                                                          completionHandler:nil]
                           failure:^(NSError *error) { DDLogError(@"Failed syncing post formats for blog %@: %@", blog.url, error); }];

    [remote checkMultiAuthorForBlog:blog
                            success:^(BOOL isMultiAuthor) {
                                [self updateMutliAuthor:isMultiAuthor forBlog:blogObjectID];
                            } failure:^(NSError *error) {
                                DDLogError(@"Failed checking muti-author status for blog %@: %@", blog.url, error);
                            }];

    CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:self.managedObjectContext];
    // Right now, none of the callers care about the results of the sync
    // We're ignoring the callbacks here but this needs refactoring
    [commentService syncCommentsForBlog:blog
                                success:nil
                                failure:nil];

    PostCategoryService *categoryService = [[PostCategoryService alloc] initWithManagedObjectContext:self.managedObjectContext];
    [categoryService syncCategoriesForBlog:blog
                                   success:nil
                                   failure:nil];

    PostService *postService = [[PostService alloc] initWithManagedObjectContext:self.managedObjectContext];
    // FIXME: this is hacky, ideally we'd do a multicall and fetch both posts/pages, but it's out of scope for this commit
    [postService syncPostsOfType:PostServiceTypePost
                         forBlog:blog
                         success:nil
                         failure:nil];
    [postService syncPostsOfType:PostServiceTypePage
                         forBlog:blog
                         success:nil
                         failure:nil];

}

- (void)syncBlogStaggeringRequests:(Blog *)blog
{
    [self staggerSyncPostsForBlog:blog];
}

- (void)staggerSyncPostsForBlog:(Blog *)blog
{
    PostService *postService = [[PostService alloc] initWithManagedObjectContext:self.managedObjectContext];
    [postService syncPostsOfType:PostServiceTypePost forBlog:blog success:^{
        [self staggerSyncPagesForBlog:blog];
    } failure:^(NSError *error) {
        [self staggerSyncPagesForBlog:blog];
    }];
}

- (void)staggerSyncPagesForBlog:(Blog *)blog
{
    PostService *postService = [[PostService alloc] initWithManagedObjectContext:self.managedObjectContext];
    [postService syncPostsOfType:PostServiceTypePage forBlog:blog success:^{
        [self staggerSyncCommentsForBlog:blog];
    } failure:^(NSError *error) {
        [self staggerSyncCommentsForBlog:blog];
    }];
}

- (void)staggerSyncCommentsForBlog:(Blog *)blog
{
    CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:self.managedObjectContext];
    [commentService syncCommentsForBlog:blog success:^{
        [self staggerSyncCategoriesForBlog:blog];
    } failure:^(NSError *error) {
        [self staggerSyncCategoriesForBlog:blog];
    }];
}

- (void)staggerSyncCategoriesForBlog:(Blog *)blog
{
    PostCategoryService *categoryService = [[PostCategoryService alloc] initWithManagedObjectContext:self.managedObjectContext];
    [categoryService syncCategoriesForBlog:blog success:^{
        [self staggerSyncBlogMetaForBlog:blog];
    } failure:^(NSError *error) {
        [self staggerSyncBlogMetaForBlog:blog];
    }];
}

- (void)staggerSyncBlogMetaForBlog:(Blog *)blog
{
    id<BlogServiceRemote> remote = [self remoteForBlog:blog];
    NSManagedObjectID *blogObjectID = blog.objectID;
    NSString *url = blog.url;
    [remote syncOptionsForBlog:blog success:[self optionsHandlerWithBlogObjectID:blogObjectID completionHandler:nil] failure:^(NSError *error) {
        DDLogError(@"Failed syncing options for blog %@: %@", url, error);
    }];

    [remote syncPostFormatsForBlog:blog success:[self postFormatsHandlerWithBlogObjectID:blogObjectID completionHandler:nil] failure:^(NSError *error) {
        DDLogError(@"Failed syncing post formats for blog %@: %@", url, error);
    }];

    [remote checkMultiAuthorForBlog:blog
                            success:^(BOOL isMultiAuthor) {
                                [self updateMutliAuthor:isMultiAuthor forBlog:blogObjectID];
                            } failure:^(NSError *error) {
                                DDLogError(@"Failed checking muti-author status for blog %@: %@", url, error);
                            }];
}

// Batch requests to sites using basic http auth to avoid auth failures in certain cases.
// See: https://github.com/wordpress-mobile/WordPress-iOS/issues/3016
- (BOOL)shouldStaggerRequestsForBlog:(Blog *)blog
{
    if (blog.account.isWpcom || blog.jetpackAccount) {
        return NO;
    }

    __block BOOL stagger = NO;
    NSURL *url = [NSURL URLWithString:blog.url];
    [[[NSURLCredentialStorage sharedCredentialStorage] allCredentials] enumerateKeysAndObjectsUsingBlock:^(NSURLProtectionSpace *ps, NSDictionary *dict, BOOL *stop) {
        [dict enumerateKeysAndObjectsUsingBlock:^(id key, NSURLCredential *credential, BOOL *stop) {
            if ([[ps host] isEqualToString:[url host]]) {
                stagger = YES;
                *stop = YES;
            }
        }];
    }];
    return stagger;
}

- (BOOL)hasVisibleWPComAccounts
{
    return [self blogCountVisibleForWPComAccounts] > 0;
}

- (NSInteger)blogCountForAllAccounts
{
    return [self blogCountWithPredicate:nil];
}

- (NSInteger)blogCountSelfHosted
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"account.isWpcom = %@"
                                                argumentArray:@[@(NO)]];
    return [self blogCountWithPredicate:predicate];
}

- (NSInteger)blogCountVisibleForWPComAccounts
{
    NSArray *subpredicates = @[
                            [self predicateForVisibleBlogs],
                            [NSPredicate predicateWithFormat:@"account.isWpcom = YES"],
                            ];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:subpredicates];
    return [self blogCountWithPredicate:predicate];
}

- (NSInteger)blogCountVisibleForAllAccounts
{
    NSPredicate *predicate = [self predicateForVisibleBlogs];
    return [self blogCountWithPredicate:predicate];
}

- (NSArray *)blogsForAllAccounts
{
    return [self blogsWithPredicate:nil];
}

///--------------------
/// @name Blog creation
///--------------------

- (Blog *)findBlogWithXmlrpc:(NSString *)xmlrpc
                   inAccount:(WPAccount *)account
{
    NSSet *foundBlogs = [account.blogs filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"xmlrpc like %@", xmlrpc]];
    if ([foundBlogs count] == 1) {
        return [foundBlogs anyObject];
    }

    // If more than one blog matches, return the first and delete the rest
    if ([foundBlogs count] > 1) {
        Blog *blogToReturn = [foundBlogs anyObject];
        for (Blog *b in foundBlogs) {
            // Choose blogs with URL not starting with https to account for a glitch in the API in early 2014
            if (!([b.url hasPrefix:HttpsPrefix])) {
                blogToReturn = b;
                break;
            }
        }

        for (Blog *b in foundBlogs) {
            if (!([b isEqual:blogToReturn])) {
                [self.managedObjectContext deleteObject:b];
            }
        }

        return blogToReturn;
    }
    return nil;
}

- (Blog *)createBlogWithAccount:(WPAccount *)account
{
    Blog *blog = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Blog class])
                                               inManagedObjectContext:self.managedObjectContext];
    blog.account = account;
    return blog;
}

- (void)removeBlog:(Blog *)blog
{
    DDLogInfo(@"<Blog:%@> remove", blog.hostURL);
    [blog.api cancelAllHTTPOperations];
    WPAccount *account = blog.account;
    WPAccount *jetpackAccount = blog.jetpackAccount;

    [self.managedObjectContext deleteObject:blog];
    [self.managedObjectContext processPendingChanges];

    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:self.managedObjectContext];
    [accountService purgeAccount:account];
    if (jetpackAccount) {
        [accountService purgeAccount:jetpackAccount];
    }

    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    [WPAnalytics refreshMetadata];
}

#pragma mark - Private methods

- (void)mergeBlogs:(NSArray *)blogs
       withAccount:(WPAccount *)account
        completion:(void (^)())completion
{
    NSSet *remoteSet = [NSSet setWithArray:[blogs valueForKey:@"xmlrpc"]];
    NSSet *localSet = [account.blogs valueForKey:@"xmlrpc"];
    NSMutableSet *toDelete = [localSet mutableCopy];
    [toDelete minusSet:remoteSet];

    if ([toDelete count] > 0) {
        for (Blog *blog in account.blogs) {
            if ([toDelete containsObject:blog.xmlrpc]) {
                [self.managedObjectContext deleteObject:blog];
            }
        }
    }

    // Go through each remote incoming blog and make sure we're up to date with titles, etc.
    // Also adds any blogs we don't have
    for (RemoteBlog *remoteBlog in blogs) {
        Blog *blog = [self findBlogWithXmlrpc:remoteBlog.xmlrpc
                                    inAccount:account];
        if (!blog && account.jetpackBlogs.count > 0) {
            blog = [self migrateRemoteJetpackBlog:remoteBlog
                                       forAccount:account];
        }
        if (!blog) {
            DDLogInfo(@"New blog from account %@: %@", account.username, remoteBlog);
            blog = [self createBlogWithAccount:account];
            blog.xmlrpc = remoteBlog.xmlrpc;
        }
        blog.url = remoteBlog.url;
        blog.blogName = [remoteBlog.title stringByDecodingXMLCharacters];
        blog.blogID = remoteBlog.ID;
        blog.isJetpack = remoteBlog.jetpack;
        
        // If non-WPcom then always default or if first from remote (assuming .com)
        if (!account.isWpcom || [blogs indexOfObject:remoteBlog] == 0) {
            account.defaultBlog = blog;
        }
    }

    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];

    if (completion != nil) {
        dispatch_async(dispatch_get_main_queue(), completion);
    }
}

/**
 Searches for Jetpack blog on the specified account and transfers it as a WPCC blog

 When a Jetpack blog appears on the results to sync blogs, we want to see if it's
 already added in the app as a self hosted site. If that's the case, this method
 will take the blog and transfer it to the account.

 It would be the equivalent of just syncing and removing the previous self hosted,
 but this will preserve the synced blog objects and local drafts.

 @param remoteBlog the RemoteBlog object with the blog details
 @param account the account in which to search for the blog
 @returns the migrated blog if found, or nil otherwise
 */
- (Blog *)migrateRemoteJetpackBlog:(RemoteBlog *)remoteBlog
                        forAccount:(WPAccount *)account
{
    Blog *jetpackBlog = [[account.jetpackBlogs filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        Blog *blogToTest = (Blog *)evaluatedObject;
        return [blogToTest.xmlrpc isEqualToString:remoteBlog.xmlrpc] && [blogToTest.dotComID isEqual:remoteBlog.ID];
    }]] anyObject];

    if (jetpackBlog) {
        DDLogInfo(@"Migrating %@ to wp.com account %@", [jetpackBlog hostURL], account.username);
        WPAccount *oldAccount = jetpackBlog.account;
        jetpackBlog.account = account;
        jetpackBlog.jetpackAccount = nil;

        /*
         Purge the blog's old account if it has no more blogs
         Generally, there's a 1-1 relationship between accounts and self-hosted
         blogs, so in most cases the self hosted account would stay invisible
         unless purged, and credentials would stay in the Keychain.
         */
        if (oldAccount.blogs.count == 0) {
            [self.managedObjectContext deleteObject:oldAccount];
        }
    }

    return jetpackBlog;
}

- (id<BlogServiceRemote>)remoteForBlog:(Blog *)blog
{
    id<BlogServiceRemote> remote;
    if (blog.restApi) {
        remote = [[BlogServiceRemoteREST alloc] initWithApi:blog.restApi];
    } else {
        remote = [[BlogServiceRemoteXMLRPC alloc] initWithApi:blog.api];
    }

    return remote;
}

- (id<AccountServiceRemote>)remoteForAccount:(WPAccount *)account
{
    if (account.restApi) {
        return [[AccountServiceRemoteREST alloc] initWithApi:account.restApi];
    }

    return [[AccountServiceRemoteXMLRPC alloc] initWithApi:account.xmlrpcApi];
}

- (Blog *)blogWithPredicate:(NSPredicate *)predicate
{
    return [[self blogsWithPredicate:predicate] firstObject];
}

- (NSArray *)blogsWithPredicate:(NSPredicate *)predicate
{
    NSFetchRequest *request = [self fetchRequestWithPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"blogName"
                                                                     ascending:YES];
    request.sortDescriptors = @[ sortDescriptor ];

    NSError *error;
    NSArray *results = [self.managedObjectContext executeFetchRequest:request
                                                                error:&error];
    if (error) {
        DDLogError(@"Couldn't fetch blogs with predicate %@: %@", predicate, error);
        return nil;
    }

    return results;
}

- (NSInteger)blogCountWithPredicate:(NSPredicate *)predicate
{
    NSFetchRequest *request = [self fetchRequestWithPredicate:predicate];

    NSError *err;
    NSUInteger count = [self.managedObjectContext countForFetchRequest:request
                                                                 error:&err];
    if (count == NSNotFound) {
        count = 0;
    }
    return count;
}

- (NSFetchRequest *)fetchRequestWithPredicate:(NSPredicate *)predicate
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Blog class])];
    request.includesSubentities = NO;
    request.predicate = predicate;
    return request;
}

- (NSPredicate *)predicateForVisibleBlogs
{
    return [NSPredicate predicateWithFormat:@"visible = YES"];
}

- (NSUInteger)countForSyncedPostsWithEntityName:(NSString *)entityName
                                        forBlog:(Blog *)blog
{
    __block NSUInteger count = 0;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(remoteStatusNumber == %@) AND (postID != NULL) AND (original == NULL) AND (blog == %@)",
                              [NSNumber numberWithInt:AbstractPostRemoteStatusSync],
                              blog];
    [request setPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date_created_gmt"
                                                                   ascending:YES];
    [request setSortDescriptors:@[sortDescriptor]];
    request.includesSubentities = NO;
    request.resultType = NSCountResultType;

    [self.managedObjectContext performBlockAndWait:^{
        NSError *error = nil;
        count = [self.managedObjectContext countForFetchRequest:request
                                                          error:&error];
    }];
    return count;
}

#pragma mark - Completion handlers

- (void)updateMutliAuthor:(BOOL)isMultiAuthor forBlog:(NSManagedObjectID *)blogObjectID
{
    [self.managedObjectContext performBlock:^{
        NSError *error;
        Blog *blog = (Blog *)[self.managedObjectContext existingObjectWithID:blogObjectID error:&error];
        if (error) {
            DDLogError(@"%@", error);
        }
        if (!blog) {
            return;
        }
        blog.isMultiAuthor = isMultiAuthor;
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    }];
}

- (OptionsHandler)optionsHandlerWithBlogObjectID:(NSManagedObjectID *)blogObjectID
                               completionHandler:(void (^)(void))completion
{
    return ^void(NSDictionary *options) {
        [self.managedObjectContext performBlock:^{
            Blog *blog = (Blog *)[self.managedObjectContext existingObjectWithID:blogObjectID
                                                                           error:nil];
            if (blog) {
                blog.options = [NSDictionary dictionaryWithDictionary:options];
                float version = [[blog version] floatValue];
                if (version < [MinimumVersion floatValue]) {
                    if (blog.lastUpdateWarning == nil
                        || [blog.lastUpdateWarning floatValue] < [MinimumVersion floatValue])
                    {
                        // TODO :: Remove UI call from service layer
                        [WPError showAlertWithTitle:NSLocalizedString(@"WordPress version too old", @"")
                                            message:[NSString stringWithFormat:NSLocalizedString(@"The site at %@ uses WordPress %@. We recommend to update to the latest version, or at least %@", @""), [blog hostname], [blog version], MinimumVersion]];
                        blog.lastUpdateWarning = MinimumVersion;
                    }
                }

                [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
            }
            if (completion) {
                completion();
            }
        }];
    };
}

- (PostFormatsHandler)postFormatsHandlerWithBlogObjectID:(NSManagedObjectID *)blogObjectID
                                       completionHandler:(void (^)(void))completion
{
    return ^void(NSDictionary *postFormats) {
        [self.managedObjectContext performBlock:^{
            Blog *blog = (Blog *)[self.managedObjectContext existingObjectWithID:blogObjectID
                                                                           error:nil];
            if (blog) {
                NSDictionary *formats = postFormats;
                if (![formats objectForKey:@"standard"]) {
                    NSMutableDictionary *mutablePostFormats = [formats mutableCopy];
                    mutablePostFormats[@"standard"] = NSLocalizedString(@"Standard", @"Standard post format label");
                    formats = [NSDictionary dictionaryWithDictionary:mutablePostFormats];
                }
                blog.postFormats = formats;

                [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
            }

            if (completion) {
                completion();
            }
        }];
    };
}

- (NSTimeZone *)timeZoneForBlog:(Blog *)blog
{
    NSString *timeZoneName = [blog getOptionValue:@"timezone"];
    NSNumber *gmtOffSet = [blog getOptionValue:@"gmt_offset"];
    id optionValue = [blog getOptionValue:@"time_zone"];
    
    NSTimeZone *timeZone = nil;
    if (timeZoneName.length > 0) {
        timeZone = [NSTimeZone timeZoneWithName:timeZoneName];
    }
    
    if (!timeZone && gmtOffSet != nil) {
        timeZone = [NSTimeZone timeZoneForSecondsFromGMT:(gmtOffSet.floatValue * OneHourInSeconds)];
    }
    
    if (!timeZone && optionValue != nil) {
        NSInteger timeZoneOffsetSeconds = [optionValue floatValue] * OneHourInSeconds;
        timeZone = [NSTimeZone timeZoneForSecondsFromGMT:timeZoneOffsetSeconds];
    }
    
    if (!timeZone) {
        timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    }
    
    return timeZone;
}

@end
