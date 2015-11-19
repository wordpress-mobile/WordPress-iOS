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
#import "RemoteBlogSettings.h"
#import "ContextManager.h"

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
                NSNumber *siteId = defaultBlog.blogID;
                NSString *blogName = defaultBlog.blogName;
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
    [remote syncOptionsForBlogID:blog.blogID
                       success:[self optionsHandlerWithBlogObjectID:blog.objectID
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
        [remote syncSettingsForBlogID:blog.blogID success:^(RemoteBlogSettings *settings) {
            [self.managedObjectContext performBlock:^{
                [self updateBlog:blogInContext settingsWithRemoteSettings:settings];
                [self.managedObjectContext save:nil];
                if (success) {
                    success();
                }
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
        [remote updateBlogSettings:[self remoteBlogSettingFromBlog:blogInContext]
                         forBlogID:blogInContext.blogID
                           success:^() {
                               [self.managedObjectContext performBlock:^{
                                   [self.managedObjectContext save:nil];
                                   if (success) {
                                       success();
                                   }
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

- (void)syncPostFormatsForBlog:(Blog *)blog
                       success:(void (^)())success
                       failure:(void (^)(NSError *error))failure
{
    id<BlogServiceRemote> remote = [self remoteForBlog:blog];
    [remote syncPostFormatsForBlogID:blog.blogID
                             success:[self postFormatsHandlerWithBlogObjectID:blog.objectID
                                                          completionHandler:success]
                             failure:failure];
}

- (void)syncBlog:(Blog *)blog
{
    NSManagedObjectID *blogObjectID = blog.objectID;
    id<BlogServiceRemote> remote = [self remoteForBlog:blog];
    [remote syncOptionsForBlogID:blog.blogID success:[self optionsHandlerWithBlogObjectID:blogObjectID
                                                               completionHandler:nil]
                       failure:^(NSError *error) { DDLogError(@"Failed syncing options for blog %@: %@", blog.url, error); }];

    [remote syncPostFormatsForBlogID:blog.blogID
                           success:[self postFormatsHandlerWithBlogObjectID:blogObjectID
                                                          completionHandler:nil]
                           failure:^(NSError *error) { DDLogError(@"Failed syncing post formats for blog %@: %@", blog.url, error); }];

    PostCategoryService *categoryService = [[PostCategoryService alloc] initWithManagedObjectContext:self.managedObjectContext];
    [categoryService syncCategoriesForBlog:blog
                                   success:nil
                                   failure:^(NSError *error) { DDLogError(@"Failed syncing categories for blog %@: %@", blog.url, error); }];

    [remote checkMultiAuthorForBlogID:blog.blogID
                              success:^(BOOL isMultiAuthor) {
                                [self updateMutliAuthor:isMultiAuthor forBlog:blogObjectID];
                              } failure:^(NSError *error) {
                                DDLogError(@"Failed checking muti-author status for blog %@: %@", blog.url, error);
                              }];
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
        if (blog.blogID != nil) {
            blogMap[blog.blogID] = blog;
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
    Blog *blog = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Blog class])
                                               inManagedObjectContext:self.managedObjectContext];
    blog.account = account;
    return blog;
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
        if (!blog && remoteBlog.jetpack) {
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
        blog.blogTagline = [remoteBlog.desc stringByDecodingXMLCharacters];
        blog.blogID = remoteBlog.ID;
        blog.isHostedAtWPcom = !remoteBlog.jetpack;
        blog.icon = remoteBlog.icon;
        blog.isAdmin = remoteBlog.isAdmin;
        blog.canUploadFiles = remoteBlog.canUploadFiles;
        blog.visible = remoteBlog.visible;
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
        return [blogToTest.xmlrpc isEqualToString:remoteBlog.xmlrpc] && [blogToTest.dotComID isEqual:remoteBlog.ID];
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
        remote = [[BlogServiceRemoteREST alloc] initWithApi:blog.restApi];
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
            blog.siteVisibility = (SiteVisibility)([[blog getOptionValue:@"blog_public"] integerValue]);
            //HACK:Sergio Estevao (2015-08-31): Because there is no direct way to
            // know if a user has permissions to change the options we check if the blog title property is read only or not.
            if ([blog.options numberForKeyPath:@"blog_title.readonly"]) {
                blog.isAdmin = ![[blog.options numberForKeyPath:@"blog_title.readonly"] boolValue];
            }

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

- (void)updateBlog:(Blog *)blog settingsWithRemoteSettings:(RemoteBlogSettings *)remoteSettings
{
    blog.blogName = remoteSettings.name;
    blog.blogTagline = remoteSettings.desc;
    if (remoteSettings.defaultCategory) {
        blog.defaultCategoryID = remoteSettings.defaultCategory;
    }
    if (remoteSettings.defaultPostFormat) {
        blog.defaultPostFormat = remoteSettings.defaultPostFormat;
    }
    if (remoteSettings.privacy) {
        blog.siteVisibility = (SiteVisibility)[remoteSettings.privacy integerValue];
    }

    blog.relatedPostsAllowed = remoteSettings.relatedPostsAllowed;
    blog.relatedPostsEnabled = remoteSettings.relatedPostsEnabled;
    blog.relatedPostsShowHeadline = remoteSettings.relatedPostsShowHeadline;
    blog.relatedPostsShowThumbnails = remoteSettings.relatedPostsShowThumbnails;
}


-(RemoteBlogSettings *)remoteBlogSettingFromBlog:(Blog *)blog
{
    RemoteBlogSettings *remoteBlogSettings = [[RemoteBlogSettings alloc] init];
    
    remoteBlogSettings.name = blog.blogName;
    remoteBlogSettings.desc = blog.blogTagline;
    remoteBlogSettings.defaultCategory = blog.defaultCategoryID;
    remoteBlogSettings.defaultPostFormat = blog.defaultPostFormat;
    remoteBlogSettings.privacy = @(blog.siteVisibility);
    remoteBlogSettings.relatedPostsAllowed = blog.relatedPostsAllowed;
    remoteBlogSettings.relatedPostsEnabled = blog.relatedPostsEnabled;
    remoteBlogSettings.relatedPostsShowHeadline = blog.relatedPostsShowHeadline;
    remoteBlogSettings.relatedPostsShowThumbnails = blog.relatedPostsShowThumbnails;
    
    return remoteBlogSettings;
}
@end
