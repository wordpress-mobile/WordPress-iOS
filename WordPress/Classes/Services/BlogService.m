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
#import "RemoteBlog.h"
#import "NSString+XMLExtensions.h"
#import "TodayExtensionService.h"
#import "ContextManager.h"
#import "WordPress-Swift.h"
#import "RemotePostType.h"
#import "PostType.h"

#import <WordPressApi/WordPressApi.h>

NSString *const LastUsedBlogURLDefaultsKey = @"LastUsedBlogURLDefaultsKey";
NSString *const EditPostViewControllerLastUsedBlogURLOldKey = @"EditPostViewControllerLastUsedBlogURL";
NSString *const WPComGetFeatures = @"wpcom.getFeatures";
NSString *const VideopressEnabled = @"videopress_enabled";
NSString *const MinimumVersion = @"3.6";
NSString *const HttpsPrefix = @"https://";
CGFloat const OneHourInSeconds = 60.0 * 60.0;

@implementation BlogService

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
    
    WP3DTouchShortcutCreator *shortcutCreator = [WP3DTouchShortcutCreator new];
    [shortcutCreator createShortcuts:YES];
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
            
            // Let's check if the account object is not nil. Otherwise we'll get an exception below.
            NSManagedObjectID *accountObjectID = account.objectID;
            if (!accountObjectID) {
                DDLogError(@"Error: The Account objectID could not be loaded");
                return;
            }
            
            // Reload the Account in the current Context
            NSError *error = nil;
            WPAccount *accountInContext = (WPAccount *)[self.managedObjectContext existingObjectWithID:accountObjectID
                                                                                                 error:&error];
            if (!accountInContext) {
                DDLogError(@"Error loading WordPress Account: %@", error);
                return;
            }
            
            [self mergeBlogs:blogs withAccount:accountInContext completion:success];
            
            // Update the Widget Configuration
            NSManagedObjectID *defaultBlogObjectID = accountInContext.defaultBlog.objectID;
            if (!defaultBlogObjectID) {
                DDLogError(@"Error: The Default Blog objectID could not be loaded");
                return;
            }
            
            Blog *defaultBlog = (Blog *)[self.managedObjectContext existingObjectWithID:defaultBlogObjectID
                                                                                  error:nil];
            TodayExtensionService *service = [TodayExtensionService new];
            BOOL widgetIsConfigured = [service widgetIsConfigured];
            
            if (WIDGETS_EXIST
                && !widgetIsConfigured
                && defaultBlog != nil
                && !defaultBlog.isDeleted) {
                NSNumber *siteId = defaultBlog.dotComID;
                NSString *blogName = defaultBlog.settings.name;
                NSTimeZone *timeZone = [self timeZoneForBlog:defaultBlog];
                NSString *oauth2Token = accountInContext.authToken;
                
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
    [remote syncOptionsWithSuccess:[self optionsHandlerWithBlogObjectID:blog.objectID
                                                  completionHandler:success]
                           failure:failure];
}

- (void)syncSettingsForBlog:(Blog *)blog
                    success:(void (^)())success
                    failure:(void (^)(NSError *error))failure
{
    NSManagedObjectID *blogID = [blog objectID];
    [self.managedObjectContext performBlock:^{
        Blog *blogInContext = (Blog *)[self.managedObjectContext objectWithID:blogID];
        if (!blogInContext) {
            if (success) {
                success();
            }
            return;
        }
        id<BlogServiceRemote> remote = [self remoteForBlog:blogInContext];
        [remote syncSettingsWithSuccess:^(RemoteBlogSettings *settings) {
            [self.managedObjectContext performBlock:^{
                [self updateSettings:blogInContext.settings withRemoteSettings:settings];
                [[ContextManager sharedInstance] saveContext:self.managedObjectContext withCompletionBlock:^{
                    if (success) {
                        success();
                    }
                }];
            }];
        }
        failure:failure];
    }];
}

- (void)updateSettingsForBlog:(Blog *)blog
                     success:(void (^)())success
                     failure:(void (^)(NSError *error))failure
{
    NSManagedObjectID *blogID = [blog objectID];
    [self.managedObjectContext performBlock:^{
        Blog *blogInContext = (Blog *)[self.managedObjectContext objectWithID:blogID];
        id<BlogServiceRemote> remote = [self remoteForBlog:blogInContext];
        [remote updateBlogSettings:[self remoteSettingFromSettings:blogInContext.settings]
                           success:^() {
                               [self.managedObjectContext performBlock:^{
                                   [[ContextManager sharedInstance] saveContext:self.managedObjectContext withCompletionBlock:^{
                                       if (success) {
                                           success();
                                       }
                                   }];
                               }];
                           }
                           failure:failure];
    }];
}

- (void)updatePassword:(NSString *)password forBlog:(Blog *)blog
{
    blog.password = password;
    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
}

- (void)migrateJetpackBlogsToXMLRPCWithCompletion:(void (^)())success
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"username != NULL AND account != NULL"];
    NSArray *blogsToMigrate = [self blogsWithPredicate:predicate];
    for (Blog *blog in blogsToMigrate) {
        DDLogInfo(@"Migrating %@ with wp.com account %@ to Jetpack XML-RPC", [blog hostURL], blog.account.username);
        blog.jetpackAccount = blog.account;
        blog.account = nil;
    }
    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    /*
     We could remove Jetpack blogs directly when we don't have a username for them,
     but triggering a sync seems safer.
     */
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:self.managedObjectContext];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    if (defaultAccount) {
        /*
         If this fails, we call success anyway. If the network fails for this request
         we still want to allow disabling REST. Next time the site list reloads, it'll
         purge the old Jetpack sites anyway
         */
        [self syncBlogsForAccount:accountService.defaultWordPressComAccount success:success failure:success];
    } else if (success) {
        success();
    }
}

- (void)syncPostTypesForBlog:(Blog *)blog
                     success:(void (^)())success
                     failure:(void (^)(NSError *error))failure
{
    NSManagedObjectID *blogObjectID = blog.objectID;
    id<BlogServiceRemote> remote = [self remoteForBlog:blog];
    [remote syncPostTypesWithSuccess:^(NSArray<RemotePostType *> *remotePostTypes) {
        [self.managedObjectContext performBlock:^{
            NSError *blogError;
            Blog *blogInContext = (Blog *)[self.managedObjectContext existingObjectWithID:blogObjectID
                                                                           error:&blogError];
            if (!blogInContext || blogError) {
                DDLogError(@"Error occurred fetching blog in context with: %@", blogError);
                if (failure) {
                    failure(blogError);
                    return;
                }
            }
            // Create new PostType entities with the RemotePostType objects.
            NSMutableSet *postTypes = [NSMutableSet setWithCapacity:remotePostTypes.count];
            NSString *entityName = NSStringFromClass([PostType class]);
            for (RemotePostType *remoteType in remotePostTypes) {
                PostType *postType = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                                                   inManagedObjectContext:self.managedObjectContext];
                postType.name = remoteType.name;
                postType.label = remoteType.label;
                postType.apiQueryable = remoteType.apiQueryable;
                [postTypes addObject:postType];
            }
            // Replace the current set of postTypes with new entities.
            blogInContext.postTypes = [NSSet setWithSet:postTypes];
            [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
            if (success) {
                success();
            }
        }];
    } failure:failure];
}

- (void)syncPostFormatsForBlog:(Blog *)blog
                       success:(void (^)())success
                       failure:(void (^)(NSError *error))failure
{
    id<BlogServiceRemote> remote = [self remoteForBlog:blog];
    [remote syncPostFormatsWithSuccess:[self postFormatsHandlerWithBlogObjectID:blog.objectID
                                                          completionHandler:success]
                               failure:failure];
}

- (void)syncBlog:(Blog *)blog completionHandler:(void (^)())completionHandler
{
    // Create a dispatch group. We'll use this to monitor completion of the various
    // remote calls and to execute the completionHandler.
    dispatch_group_t syncGroup = dispatch_group_create();

    NSManagedObjectID *blogObjectID = blog.objectID;
    id<BlogServiceRemote> remote = [self remoteForBlog:blog];

    dispatch_group_enter(syncGroup);
    [remote syncOptionsWithSuccess:[self optionsHandlerWithBlogObjectID:blogObjectID
                                                      completionHandler:^{
                                                          dispatch_group_leave(syncGroup);
                                                      }]
                           failure:^(NSError *error) {
                               DDLogError(@"Failed syncing options for blog %@: %@", blog.url, error);
                               dispatch_group_leave(syncGroup);
                           }];

    dispatch_group_enter(syncGroup);
    [remote syncPostFormatsWithSuccess:[self postFormatsHandlerWithBlogObjectID:blogObjectID
                                                              completionHandler:^{
                                                                  dispatch_group_leave(syncGroup);
                                                              }]
                               failure:^(NSError *error) {
                                   DDLogError(@"Failed syncing post formats for blog %@: %@", blog.url, error);
                                   dispatch_group_leave(syncGroup);
                               }];

    PostCategoryService *categoryService = [[PostCategoryService alloc] initWithManagedObjectContext:self.managedObjectContext];
    dispatch_group_enter(syncGroup);
    [categoryService syncCategoriesForBlog:blog
                                   success:^{
                                       dispatch_group_leave(syncGroup);
                                   }
                                   failure:^(NSError *error) {
                                       DDLogError(@"Failed syncing categories for blog %@: %@", blog.url, error);
                                       dispatch_group_leave(syncGroup);
                                   }];

    dispatch_group_enter(syncGroup);
    [remote checkMultiAuthorWithSuccess:^(BOOL isMultiAuthor) {
        [self updateMutliAuthor:isMultiAuthor forBlog:blogObjectID];
        dispatch_group_leave(syncGroup);

    } failure:^(NSError *error) {
        DDLogError(@"Failed checking muti-author status for blog %@: %@", blog.url, error);
        dispatch_group_leave(syncGroup);
    }];

    // When everything has left the syncGroup (all calls have ended with success
    // or failure) perform the completionHandler
    dispatch_group_notify(syncGroup, dispatch_get_main_queue(),^{
        if (completionHandler) {
            completionHandler();
        }
    });
}

- (BOOL)hasVisibleWPComAccounts
{
    return [self blogCountVisibleForWPComAccounts] > 0;
}

- (BOOL)hasAnyJetpackBlogs
{
    NSPredicate *jetpackManagedPredicate = [NSPredicate predicateWithFormat:@"account != NULL AND isHostedAtWPcom = NO"];
    NSInteger jetpackManagedCount = [self blogCountWithPredicate:jetpackManagedPredicate];
    if (jetpackManagedCount > 0) {
        return YES;
    }

    NSArray *selfHostedBlogs = [self blogsWithNoAccount];
    NSArray *jetpackUnmanagedBlogs = [selfHostedBlogs wp_filter:^BOOL(Blog *blog) {
        return blog.jetpack.isConnected;
    }];

    return [jetpackUnmanagedBlogs count] > 0;
}

- (NSInteger)blogCountForAllAccounts
{
    return [self blogCountWithPredicate:nil];
}

- (NSInteger)blogCountSelfHosted
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"account = NULL"];
    return [self blogCountWithPredicate:predicate];
}

- (NSInteger)blogCountForWPComAccounts
{
    return [self blogCountWithPredicate:[NSPredicate predicateWithFormat:@"account != NULL"]];
}

- (NSInteger)blogCountVisibleForWPComAccounts
{
    NSArray *subpredicates = @[
                            [self predicateForVisibleBlogs],
                            [NSPredicate predicateWithFormat:@"account != NULL"],
                            ];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:subpredicates];
    return [self blogCountWithPredicate:predicate];
}

- (NSInteger)blogCountVisibleForAllAccounts
{
    NSPredicate *predicate = [self predicateForVisibleBlogs];
    return [self blogCountWithPredicate:predicate];
}

- (NSArray *)blogsWithNoAccount
{
    NSPredicate *predicate = [self predicateForNoAccount];
    return [self blogsWithPredicate:predicate];
}

- (NSArray *)blogsForAllAccounts
{
    return [self blogsWithPredicate:nil];
}

- (NSDictionary *)blogsForAllAccountsById
{
    NSMutableDictionary *blogMap = [NSMutableDictionary dictionary];
    NSArray *allBlogs = [self blogsWithPredicate:nil];
    
    for (Blog *blog in allBlogs) {
        if (blog.dotComID != nil) {
            blogMap[blog.dotComID] = blog;
        }
    }
    
    return blogMap;
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

- (Blog *)findBlogWithXmlrpc:(NSString *)xmlrpc
                 andUsername:(NSString *)username
{
    NSArray *foundBlogs = [self blogsWithPredicate:[NSPredicate predicateWithFormat:@"xmlrpc = %@ AND username = %@", xmlrpc, username]];
    return [foundBlogs firstObject];
}

- (Blog *)createBlogWithAccount:(WPAccount *)account
{
    NSString *entityName = NSStringFromClass([Blog class]);
    Blog *blog = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                               inManagedObjectContext:self.managedObjectContext];
    blog.account = account;
    blog.settings = [self createSettingsWithBlog:blog];
    return blog;
}

- (BlogSettings *)createSettingsWithBlog:(Blog *)blog
{
    NSString *entityName = [BlogSettings classNameWithoutNamespaces];
    BlogSettings *settings = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                                           inManagedObjectContext:self.managedObjectContext];
    settings.blog = blog;
    return settings;
}

- (void)removeBlog:(Blog *)blog
{
    DDLogInfo(@"<Blog:%@> remove", blog.hostURL);
    [blog.api cancelAllHTTPOperations];
    WPAccount *jetpackAccount = blog.jetpackAccount;

    [self.managedObjectContext deleteObject:blog];
    [self.managedObjectContext processPendingChanges];

    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:self.managedObjectContext];
    if (jetpackAccount) {
        [accountService purgeAccount:jetpackAccount];
    }

    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    [WPAnalytics refreshMetadata];
}

#pragma mark - Private methods

- (void)mergeBlogs:(NSArray<RemoteBlog *> *)blogs withAccount:(WPAccount *)account completion:(void (^)())completion
{
    // Nuke dead blogs
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
        Blog *blog = [self findBlogWithXmlrpc:remoteBlog.xmlrpc inAccount:account];
        
        if (!blog && remoteBlog.jetpack) {
            blog = [self migrateRemoteJetpackBlog:remoteBlog forAccount:account];
        }
        
        if (!blog) {
            DDLogInfo(@"New blog from account %@: %@", account.username, remoteBlog);
            blog = [self createBlogWithAccount:account];
            blog.xmlrpc = remoteBlog.xmlrpc;
        }
        
        if (!blog.settings) {
            blog.settings = [self createSettingsWithBlog:blog];
        }
        
        blog.url = remoteBlog.url;
        blog.dotComID = remoteBlog.blogID;
        blog.isHostedAtWPcom = !remoteBlog.jetpack;
        blog.icon = remoteBlog.icon;
        blog.isAdmin = remoteBlog.isAdmin;
        blog.visible = remoteBlog.visible;
        blog.options = remoteBlog.options;
        blog.planID = remoteBlog.planID;

        // Update 'Top Level' Settings
        BlogSettings *settings = blog.settings;
        settings.name = [remoteBlog.name stringByDecodingXMLCharacters];
        settings.tagline = [remoteBlog.tagline stringByDecodingXMLCharacters];
    }

    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];

    if (completion != nil) {
        dispatch_async(dispatch_get_main_queue(), completion);
    }
}

/**
 Searches for Jetpack blog that has already been added as a self hosted to the app
 and migrates it to use Jetpack REST.

 When a Jetpack blog appears on the results to sync blogs, we want to see if it's
 already added in the app as a self hosted site. If that's the case, this method
 will take the blog and transfer it to the account.

 It would be the equivalent of just syncing and removing the previous self hosted,
 but this will preserve the synced blog objects and local drafts.

 @param remoteBlog the RemoteBlog object with the blog details
 @param account the account that the blog should be migrated to
 @returns the migrated blog if found, or nil otherwise
 */
- (Blog *)migrateRemoteJetpackBlog:(RemoteBlog *)remoteBlog
                        forAccount:(WPAccount *)account
{
    NSArray *blogsWithNoAccount = [self blogsWithNoAccount];
    Blog *jetpackBlog = [[blogsWithNoAccount wp_filter:^BOOL(Blog *blogToTest) {
        return [blogToTest.xmlrpc isEqualToString:remoteBlog.xmlrpc] && [blogToTest.dotComID isEqual:remoteBlog.blogID];
    }] firstObject];

    if (jetpackBlog) {
        DDLogInfo(@"Migrating %@ to wp.com account %@", [jetpackBlog hostURL], account.username);
        jetpackBlog.account = account;
        jetpackBlog.jetpackAccount = nil;
    }

    return jetpackBlog;
}

- (id<BlogServiceRemote>)remoteForBlog:(Blog *)blog
{
    id<BlogServiceRemote> remote;
    if (blog.restApi) {
        remote = [[BlogServiceRemoteREST alloc] initWithApi:blog.restApi siteID:blog.dotComID];
    } else {
        remote = [[BlogServiceRemoteXMLRPC alloc] initWithApi:blog.api username:blog.username password:blog.password];
    }

    return remote;
}

- (id<AccountServiceRemote>)remoteForAccount:(WPAccount *)account
{
    return [[AccountServiceRemoteREST alloc] initWithApi:account.restApi];
}

- (Blog *)blogWithPredicate:(NSPredicate *)predicate
{
    return [[self blogsWithPredicate:predicate] firstObject];
}

- (NSArray *)blogsWithPredicate:(NSPredicate *)predicate
{
    NSFetchRequest *request = [self fetchRequestWithPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"settings.name"
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

- (NSPredicate *)predicateForNoAccount
{
    return [NSPredicate predicateWithFormat:@"account = NULL"];
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
            if (!blog) {
                if (completion) {
                    completion();
                }
                return;
            }
            blog.options = [NSDictionary dictionaryWithDictionary:options];

            CGFloat version = [[blog version] floatValue];
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

            [[ContextManager sharedInstance] saveContext:self.managedObjectContext withCompletionBlock:completion];
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
                if (![formats objectForKey:PostFormatStandard]) {
                    NSMutableDictionary *mutablePostFormats = [formats mutableCopy];
                    mutablePostFormats[PostFormatStandard] = NSLocalizedString(@"Standard", @"Standard post format label");
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

- (void)updateSettings:(BlogSettings *)settings withRemoteSettings:(RemoteBlogSettings *)remoteSettings
{
    NSParameterAssert(settings);
    NSParameterAssert(remoteSettings);
    
    // Transformables
    NSSet *separatedBlacklistKeys = [remoteSettings.commentsBlacklistKeys uniqueStringComponentsSeparatedByNewline];
    NSSet *separatedModerationKeys = [remoteSettings.commentsModerationKeys uniqueStringComponentsSeparatedByNewline];
    
    // General
    settings.name = remoteSettings.name;
    settings.tagline = remoteSettings.tagline;
    settings.privacy = remoteSettings.privacy ?: settings.privacy;
    settings.languageID = remoteSettings.languageID ?: settings.languageID;
    
    // Writing
    settings.defaultCategoryID = remoteSettings.defaultCategoryID ?: settings.defaultCategoryID;
    settings.defaultPostFormat = remoteSettings.defaultPostFormat ?: settings.defaultPostFormat;

    // Discussion
    settings.commentsAllowed = [remoteSettings.commentsAllowed boolValue];
    settings.commentsBlacklistKeys = separatedBlacklistKeys;
    settings.commentsCloseAutomatically = [remoteSettings.commentsCloseAutomatically boolValue];
    settings.commentsCloseAutomaticallyAfterDays = remoteSettings.commentsCloseAutomaticallyAfterDays;
    settings.commentsFromKnownUsersWhitelisted = [remoteSettings.commentsFromKnownUsersWhitelisted boolValue];
    
    settings.commentsMaximumLinks = remoteSettings.commentsMaximumLinks;
    settings.commentsModerationKeys = separatedModerationKeys;
    
    settings.commentsPagingEnabled = [remoteSettings.commentsPagingEnabled boolValue];
    settings.commentsPageSize = remoteSettings.commentsPageSize;
    
    settings.commentsRequireManualModeration = [remoteSettings.commentsRequireManualModeration boolValue];
    settings.commentsRequireNameAndEmail = [remoteSettings.commentsRequireNameAndEmail boolValue];
    settings.commentsRequireRegistration = [remoteSettings.commentsRequireRegistration boolValue];
    
    settings.commentsSortOrderAscending = remoteSettings.commentsSortOrderAscending;
    
    settings.commentsThreadingDepth = remoteSettings.commentsThreadingDepth;
    settings.commentsThreadingEnabled = [remoteSettings.commentsThreadingEnabled boolValue];
    
    settings.pingbackInboundEnabled = [remoteSettings.pingbackInboundEnabled boolValue];
    settings.pingbackOutboundEnabled = [remoteSettings.pingbackOutboundEnabled boolValue];

    // Related Posts
    settings.relatedPostsAllowed = [remoteSettings.relatedPostsAllowed boolValue];
    settings.relatedPostsEnabled = [remoteSettings.relatedPostsEnabled boolValue];
    settings.relatedPostsShowHeadline = [remoteSettings.relatedPostsShowHeadline boolValue];
    settings.relatedPostsShowThumbnails = [remoteSettings.relatedPostsShowThumbnails boolValue];

    // Sharing
    settings.sharingButtonStyle = remoteSettings.sharingButtonStyle;
    settings.sharingLabel = remoteSettings.sharingLabel;
    settings.sharingTwitterName = remoteSettings.sharingTwitterName;
    settings.sharingCommentLikesEnabled = [remoteSettings.sharingCommentLikesEnabled boolValue];
    settings.sharingDisabledLikes = [remoteSettings.sharingDisabledLikes boolValue];
    settings.sharingDisabledReblogs = [remoteSettings.sharingDisabledReblogs boolValue];
}

- (RemoteBlogSettings *)remoteSettingFromSettings:(BlogSettings *)settings
{
    NSParameterAssert(settings);
    RemoteBlogSettings *remoteSettings = [RemoteBlogSettings new];

    // Transformables
    NSString *joinedBlacklistKeys = [[settings.commentsBlacklistKeys allObjects] componentsJoinedByString:@"\n"];
    NSString *joinedModerationKeys = [[settings.commentsModerationKeys allObjects] componentsJoinedByString:@"\n"];
    
    // General
    remoteSettings.name = settings.name;
    remoteSettings.tagline = settings.tagline;
    remoteSettings.privacy = settings.privacy;
    remoteSettings.languageID = settings.languageID;
    
    // Writing
    remoteSettings.defaultCategoryID = settings.defaultCategoryID;
    remoteSettings.defaultPostFormat = settings.defaultPostFormat;

    // Discussion
    remoteSettings.commentsAllowed = @(settings.commentsAllowed);
    remoteSettings.commentsBlacklistKeys = joinedBlacklistKeys;
    remoteSettings.commentsCloseAutomatically = @(settings.commentsCloseAutomatically);
    remoteSettings.commentsCloseAutomaticallyAfterDays = settings.commentsCloseAutomaticallyAfterDays;
    remoteSettings.commentsFromKnownUsersWhitelisted = @(settings.commentsFromKnownUsersWhitelisted);
    
    remoteSettings.commentsMaximumLinks = settings.commentsMaximumLinks;
    remoteSettings.commentsModerationKeys = joinedModerationKeys;
    
    remoteSettings.commentsPagingEnabled = @(settings.commentsPagingEnabled);
    remoteSettings.commentsPageSize = settings.commentsPageSize;
    
    remoteSettings.commentsRequireManualModeration = @(settings.commentsRequireManualModeration);
    remoteSettings.commentsRequireNameAndEmail = @(settings.commentsRequireNameAndEmail);
    remoteSettings.commentsRequireRegistration = @(settings.commentsRequireRegistration);

    remoteSettings.commentsSortOrderAscending = settings.commentsSortOrderAscending;
    
    remoteSettings.commentsThreadingDepth = settings.commentsThreadingDepth;
    remoteSettings.commentsThreadingEnabled = @(settings.commentsThreadingEnabled);
    
    remoteSettings.pingbackInboundEnabled = @(settings.pingbackInboundEnabled);
    remoteSettings.pingbackOutboundEnabled = @(settings.pingbackOutboundEnabled);
    
    // Related Posts
    remoteSettings.relatedPostsAllowed = @(settings.relatedPostsAllowed);
    remoteSettings.relatedPostsEnabled = @(settings.relatedPostsEnabled);
    remoteSettings.relatedPostsShowHeadline = @(settings.relatedPostsShowHeadline);
    remoteSettings.relatedPostsShowThumbnails = @(settings.relatedPostsShowThumbnails);

    // Sharing
    remoteSettings.sharingButtonStyle = settings.sharingButtonStyle;
    remoteSettings.sharingLabel =  settings.sharingLabel;
    remoteSettings.sharingTwitterName = settings.sharingTwitterName;
    remoteSettings.sharingCommentLikesEnabled = @(settings.sharingCommentLikesEnabled);
    remoteSettings.sharingDisabledLikes = @(settings.sharingDisabledLikes);
    remoteSettings.sharingDisabledReblogs = @(settings.sharingDisabledReblogs);
    
    return remoteSettings;
}

@end
