#import "BlogService.h"
#import "Blog.h"
#import "WPAccount.h"
#import "AccountService.h"
#import "CoreDataStack.h"
#import "WPError.h"
#import "Media.h"
#import "PostCategoryService.h"
#import "CommentService.h"
#import "PostService.h"
#import "WordPress-Swift.h"
#import "PostType.h"
@import WordPressKit;
@import WordPressShared;

@class Comment;

NSString *const WPComGetFeatures = @"wpcom.getFeatures";
NSString *const VideopressEnabled = @"videopress_enabled";
NSString *const WordPressMinimumVersion = @"4.0";
NSString *const HttpsPrefix = @"https://";
NSString *const WPBlogUpdatedNotification = @"WPBlogUpdatedNotification";
NSString *const WPBlogSettingsUpdatedNotification = @"WPBlogSettingsUpdatedNotification";

@implementation BlogService

- (void)syncBlogsForAccount:(WPAccount *)account
                    success:(void (^)(void))success
                    failure:(void (^)(NSError *error))failure
{
    DDLogMethod();

    id<AccountServiceRemote> remote = [self remoteForAccount:account];
    
    BOOL filterJetpackSites = [AppConfiguration showJetpackSitesOnly];

    [remote getBlogs:filterJetpackSites success:^(NSArray *blogs) {
        [[[JetpackCapabilitiesService alloc] init] syncWithBlogs:blogs success:^(NSArray<RemoteBlog *> *blogs) {
            [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
                [self mergeBlogs:blogs withAccountID:account.objectID inContext:context];
            } completion:success onQueue:dispatch_get_main_queue()];
        }];
    } failure:^(NSError *error) {
        DDLogError(@"Error syncing blogs: %@", error);

        if (failure) {
            failure(error);
        }
    }];
}

- (void)syncBlog:(Blog *)blog
         success:(void (^)(void))success
         failure:(void (^)(NSError *error))failure
{
    id<BlogServiceRemote> remote = [self remoteForBlog:blog];
    if ([remote isKindOfClass:[BlogServiceRemoteXMLRPC class]]) {
        BlogServiceRemoteXMLRPC *xmlrpcRemote = remote;
        [xmlrpcRemote syncBlogOptionsWithSuccess:[self optionsHandlerWithBlogObjectID:blog.objectID
                                                                    completionHandler:success]
                                         failure:failure];
    } else if ([remote isKindOfClass:[BlogServiceRemoteREST class]]) {
        BlogServiceRemoteREST *restRemote = remote;
        [restRemote syncBlogWithSuccess:[self blogDetailsHandlerWithBlogObjectID:blog.objectID
                                                               completionHandler:success]
                                failure:failure];
    }
}

- (void)syncBlogAndAllMetadata:(Blog *)blog completionHandler:(void (^)(void))completionHandler
{
    // Create a dispatch group. We'll use this to monitor completion of the various
    // remote calls and to execute the completionHandler.
    dispatch_group_t syncGroup = dispatch_group_create();

    NSManagedObjectID *blogObjectID = blog.objectID;
    id<BlogServiceRemote> remote = [self remoteForBlog:blog];

    if ([remote isKindOfClass:[BlogServiceRemoteXMLRPC class]]) {
        dispatch_group_enter(syncGroup);
        BlogServiceRemoteXMLRPC *xmlrpcRemote = remote;
        [xmlrpcRemote syncBlogOptionsWithSuccess:[self optionsHandlerWithBlogObjectID:blogObjectID
                                                                    completionHandler:^{
                                                                        dispatch_group_leave(syncGroup);
                                                                    }]
                                         failure:^(NSError *error) {
                                             DDLogError(@"Failed syncing options for blog %@: %@", blog.url, error);
                                             dispatch_group_leave(syncGroup);
                                         }];
    }

    if ([remote isKindOfClass:[BlogServiceRemoteREST class]]) {
        dispatch_group_enter(syncGroup);
        BlogServiceRemoteREST *restRemote = remote;
        [restRemote syncBlogWithSuccess:[self blogDetailsHandlerWithBlogObjectID:blogObjectID
                                                               completionHandler:^{
                                                                   dispatch_group_leave(syncGroup);
                                                               }]
                                failure:^(NSError *error) {
                                    DDLogError(@"Failed syncing site details for blog %@: %@", blog.url, error);
                                    dispatch_group_leave(syncGroup);
                                }];

        dispatch_group_enter(syncGroup);
        [restRemote syncBlogSettingsWithSuccess:^(RemoteBlogSettings *settings) {
            [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
                Blog *blogInContext = (Blog *)[context existingObjectWithID:blogObjectID error:nil];
                if (blogInContext) {
                    [self updateSettings:blogInContext.settings withRemoteSettings:settings];
                }
            } completion:^{
                dispatch_group_leave(syncGroup);
            } onQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
        } failure:^(NSError *error) {
            DDLogError(@"Failed syncing settings for blog %@: %@", blog.url, error);
            dispatch_group_leave(syncGroup);
        }];
    }

    dispatch_group_enter(syncGroup);
    [remote syncPostFormatsWithSuccess:[self postFormatsHandlerWithBlogObjectID:blogObjectID
                                                              completionHandler:^{
                                                                  dispatch_group_leave(syncGroup);
                                                              }]
                               failure:^(NSError *error) {
                                   DDLogError(@"Failed syncing post formats for blog %@: %@", blog.url, error);
                                   dispatch_group_leave(syncGroup);
                               }];

    PostCategoryService *categoryService = [[PostCategoryService alloc] initWithCoreDataStack:self.coreDataStack];
    dispatch_group_enter(syncGroup);
    [categoryService syncCategoriesForBlog:blog
                                   success:^{
                                       dispatch_group_leave(syncGroup);
                                   }
                                   failure:^(NSError *error) {
                                       DDLogError(@"Failed syncing categories for blog %@: %@", blog.url, error);
                                       dispatch_group_leave(syncGroup);
                                   }];

    SharingSyncService *sharingService = [[SharingSyncService alloc] initWithCoreDataStack:self.coreDataStack];
    dispatch_group_enter(syncGroup);
    [sharingService syncPublicizeConnectionsForBlog:blog
                                            success:^{
                                                dispatch_group_leave(syncGroup);
                                            }
                                            failure:^(NSError *error) {
                                                DDLogError(@"Failed syncing publicize connections for blog %@: %@", blog.url, error);
                                                dispatch_group_leave(syncGroup);
                                            }];

    SharingService *publicizeService = [[SharingService alloc] initWithContextManager:[ContextManager sharedInstance]];
    dispatch_group_enter(syncGroup);
    [publicizeService syncPublicizeServicesForBlog:blog success:^{
        dispatch_group_leave(syncGroup);
    } failure:^(NSError * _Nullable error) {
        DDLogError(@"Failed syncing publicize services for blog %@: %@", blog.url, error);
        dispatch_group_leave(syncGroup);
    }];

    if ([RemoteFeature enabled:RemoteFeatureFlagJetpackSocialImprovements] && blog.dotComID != nil) {
        JetpackSocialService *jetpackSocialService = [[JetpackSocialService alloc] initWithContextManager:ContextManager.sharedInstance];
        dispatch_group_enter(syncGroup);
        [jetpackSocialService syncSharingLimitWithDotComID:blog.dotComID success:^{
            dispatch_group_leave(syncGroup);
        } failure:^(NSError * _Nullable error) {
            DDLogError(@"Failed syncing publicize sharing limit for blog %@: %@", blog.url, error);
            dispatch_group_leave(syncGroup);
        }];
    }

    dispatch_group_enter(syncGroup);
    [remote getAllAuthorsWithSuccess:^(NSArray<RemoteUser *> *users) {
        [self updateMultiAuthor:users forBlog:blogObjectID completionHandler:^{
            dispatch_group_leave(syncGroup);
        }];
    } failure:^(NSError *error) {
        DDLogError(@"Failed checking multi-author status for blog %@: %@", blog.url, error);
        dispatch_group_leave(syncGroup);
    }];

    PlanService *planService = [[PlanService alloc] initWithCoreDataStack:self.coreDataStack];
    dispatch_group_enter(syncGroup);
    [planService getWpcomPlans:blog.account
                       success:^{
        dispatch_group_leave(syncGroup);
    } failure:^(NSError *error) {
        DDLogError(@"Failed updating plans: %@", error);
        dispatch_group_leave(syncGroup);
    }];

    dispatch_group_enter(syncGroup);
    [planService plansWithPricesForBlog:blog success:^{
        dispatch_group_leave(syncGroup);
    } failure:^(NSError *error) {
        DDLogError(@"Failed checking domain credit for site %@: %@", blog.url, error);
        dispatch_group_leave(syncGroup);
    }];

    EditorSettingsService *editorService = [[EditorSettingsService alloc] initWithCoreDataStack:self.coreDataStack];
    dispatch_group_enter(syncGroup);
    [editorService syncEditorSettingsForBlog:blog success:^{
        dispatch_group_leave(syncGroup);
    } failure:^(NSError * _Nonnull __unused error) {
        DDLogError(@"Failed to sync Editor settings");
        dispatch_group_leave(syncGroup);
    }];
    
    if ([DomainsDashboardCardHelper isFeatureEnabled] || [FreeToPaidPlansDashboardCardHelper isFeatureEnabled]) {
        dispatch_group_enter(syncGroup);
        [self refreshDomainsFor:blog success:^{
            dispatch_group_leave(syncGroup);
        } failure:^(NSError * _Nonnull error) {
            DDLogError(@"Failed refreshing domains: %@", error);
            dispatch_group_leave(syncGroup);
        }];
    }
    
    // When everything has left the syncGroup (all calls have ended with success
    // or failure) perform the completionHandler
    dispatch_group_notify(syncGroup, dispatch_get_main_queue(),^{
        if (completionHandler) {
            completionHandler();
        }
    });
}

- (void)syncSettingsForBlog:(Blog *)blog
                    success:(void (^)(void))success
                    failure:(void (^)(NSError *error))failure
{
    NSManagedObjectID *blogID = [blog objectID];
    [self.coreDataStack.mainContext performBlock:^{
        Blog *blogInContext = (Blog *)[self.coreDataStack.mainContext objectWithID:blogID];
        if (!blogInContext) {
            if (success) {
                success();
            }
            return;
        }

        void(^updateOnSuccess)(RemoteBlogSettings *) = ^(RemoteBlogSettings *remoteSettings) {
            [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
                Blog *blogInContext = (Blog *)[context objectWithID:blogID];
                [self updateSettings:blogInContext.settings withRemoteSettings:remoteSettings];
            } completion:success onQueue:dispatch_get_main_queue()];
        };
        id<BlogServiceRemote> remote = [self remoteForBlog:blogInContext];
        if ([remote isKindOfClass:[BlogServiceRemoteXMLRPC class]]) {

            BlogServiceRemoteXMLRPC *xmlrpcRemote = remote;
            [xmlrpcRemote syncBlogOptionsWithSuccess:^(NSDictionary *options) {
                RemoteBlogSettings *remoteSettings = [RemoteBlogOptionsHelper remoteBlogSettingsFromXMLRPCDictionaryOptions:options];
                updateOnSuccess(remoteSettings);
            } failure:failure];

        } else if ([remote isKindOfClass:[BlogServiceRemoteREST class]]) {

            BlogServiceRemoteREST *restRemote = remote;
            [restRemote syncBlogSettingsWithSuccess:^(RemoteBlogSettings *settings) {
                updateOnSuccess(settings);
            } failure:failure];
        }
    }];
}

- (void)syncAuthorsForBlog:(Blog *)blog
                    success:(void (^)(void))success
                    failure:(void (^)(NSError *error))failure
{
    NSManagedObjectID *blogObjectID = blog.objectID;
    id<BlogServiceRemote> remote = [self remoteForBlog:blog];

    [remote getAllAuthorsWithSuccess:^(NSArray<RemoteUser *> *users) {
        [self updateMultiAuthor:users forBlog:blogObjectID completionHandler:success];
    } failure:^(NSError *error) {
        DDLogError(@"Failed checking multi-author status for blog %@: %@", blog.url, error);
        failure(error);
    }];
}

- (void)updateSettingsForBlog:(Blog *)blog
                     success:(void (^)(void))success
                     failure:(void (^)(NSError *error))failure
{
    NSManagedObjectID *blogID = [blog objectID];
    NSManagedObjectContext *context = self.coreDataStack.mainContext;
    [context performBlock:^{
        Blog *blogInContext = (Blog *)[context objectWithID:blogID];
        id<BlogServiceRemote> remote = [self remoteForBlog:blogInContext];
        RemoteBlogSettings *remoteSettings = [self remoteSettingFromSettings:blogInContext.settings];

        void(^onSuccess)(void) = ^() {
            [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
                Blog *blogInContext = (Blog *)[context existingObjectWithID:blogID error:nil];
                if (blogInContext) {
                    [self updateSettings:blogInContext.settings withRemoteSettings:remoteSettings];
                }
            } completion:^{
                if (success) {
                    success();
                }
            } onQueue:dispatch_get_main_queue()];
        };

        if ([remote isKindOfClass:[BlogServiceRemoteXMLRPC class]]) {

            BlogServiceRemoteXMLRPC *xmlrpcRemote = remote;
            [xmlrpcRemote updateBlogOptionsWith:[RemoteBlogOptionsHelper remoteOptionsForUpdatingBlogTitleAndTagline:remoteSettings]
                                        success:onSuccess
                                        failure:failure];

        } else if([remote isKindOfClass:[BlogServiceRemoteREST class]]) {

            BlogServiceRemoteREST *restRemote = remote;
            [restRemote updateBlogSettings:remoteSettings
                               success:onSuccess
                               failure:failure];
        }
    }];
}

- (void)syncPostTypesForBlog:(Blog *)blog
                     success:(void (^)(void))success
                     failure:(void (^)(NSError *error))failure
{
    NSManagedObjectID *blogObjectID = blog.objectID;
    id<BlogServiceRemote> remote = [self remoteForBlog:blog];
    [remote syncPostTypesWithSuccess:^(NSArray<RemotePostType *> *remotePostTypes) {
        [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
            NSError *blogError;
            Blog *blogInContext = (Blog *)[context existingObjectWithID:blogObjectID error:&blogError];
            if (!blogInContext || blogError) {
                DDLogError(@"Error occurred fetching blog in context with: %@", blogError);
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (failure) {
                        failure(blogError);
                        return;
                    }
                });
            }
            // Create new PostType entities with the RemotePostType objects.
            NSMutableSet *postTypes = [NSMutableSet setWithCapacity:remotePostTypes.count];
            NSString *entityName = NSStringFromClass([PostType class]);
            for (RemotePostType *remoteType in remotePostTypes) {
                PostType *postType = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                                                   inManagedObjectContext:context];
                postType.name = remoteType.name;
                postType.label = remoteType.label;
                postType.apiQueryable = remoteType.apiQueryable;
                [postTypes addObject:postType];
            }
            // Replace the current set of postTypes with new entities.
            blogInContext.postTypes = [NSSet setWithSet:postTypes];
        } completion:success onQueue:dispatch_get_main_queue()];
    } failure:failure];
}

- (void)syncPostFormatsForBlog:(Blog *)blog
                       success:(void (^)(void))success
                       failure:(void (^)(NSError *error))failure
{
    id<BlogServiceRemote> remote = [self remoteForBlog:blog];
    [remote syncPostFormatsWithSuccess:[self postFormatsHandlerWithBlogObjectID:blog.objectID
                                                          completionHandler:success]
                               failure:failure];
}

///--------------------
/// @name Blog creation
///--------------------

- (Blog *)findBlogWithDotComID:(NSNumber *)dotComID
                     inAccount:(WPAccount *)account
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"dotComID = %@", dotComID];
    return [[account.blogs filteredSetUsingPredicate:predicate] anyObject];
}

- (void)removeBlog:(Blog *)blog
{
    DDLogInfo(@"<Blog:%@> remove", blog.hostURL);
    [blog.xmlrpcApi invalidateAndCancelTasks];
    [self unscheduleBloggingRemindersFor:blog];

    WPAccount *account = blog.account;

    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        Blog *blogInContext = [context existingObjectWithID:blog.objectID error:nil];
        [context deleteObject:blogInContext];
    }];

    if (account) {
        AccountService *accountService = [[AccountService alloc] initWithCoreDataStack:self.coreDataStack];
        [accountService purgeAccountIfUnused:account];
    }

    [WPAnalytics refreshMetadata];
}

- (void)associateSyncedBlogsToJetpackAccount:(WPAccount *)account
                                     success:(void (^)(void))success
                                     failure:(void (^)(NSError *error))failure
{
    AccountServiceRemoteREST *remote = [[AccountServiceRemoteREST alloc] initWithWordPressComRestApi:account.wordPressComRestApi];
    
    BOOL filterJetpackSites = [AppConfiguration showJetpackSitesOnly];
    
    [remote getBlogs:filterJetpackSites success:^(NSArray *remoteBlogs) {
        [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
            NSMutableSet *accountBlogIDs = [NSMutableSet new];
            for (RemoteBlog *remoteBlog in remoteBlogs) {
                [accountBlogIDs addObject:remoteBlog.blogID];
            }

            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Blog class])];
            request.predicate = [NSPredicate predicateWithFormat:@"account = NULL"];
            NSArray *blogs = [context executeFetchRequest:request error:nil];
            blogs = [blogs filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary * __unused bindings) {
                Blog *blog = (Blog *)evaluatedObject;
                NSNumber *jetpackBlogID = blog.jetpack.siteID;
                return jetpackBlogID && [accountBlogIDs containsObject:jetpackBlogID];
            }]];

            WPAccount *accountInContext = [context existingObjectWithID:account.objectID error:nil];
            [accountInContext addBlogs:[NSSet setWithArray:blogs]];
        } completion:success onQueue:dispatch_get_main_queue()];
    } failure:failure];
}

#pragma mark - Private methods

- (void)mergeBlogs:(NSArray<RemoteBlog *> *)blogs withAccountID:(NSManagedObjectID *)accountID inContext:(NSManagedObjectContext *)context
{
    // Nuke dead blogs
    NSError *error = nil;
    WPAccount *account = [context existingObjectWithID:accountID error:&error];
    if (account == nil) {
        DDLogInfo(@"Can't find the account. User may have signed out. Error: %@", error);
        return;
    }

    NSSet *remoteSet = [NSSet setWithArray:[blogs valueForKey:@"blogID"]];
    NSSet *localSet = [account.blogs valueForKey:@"dotComID"];
    NSMutableSet *toDelete = [localSet mutableCopy];
    [toDelete minusSet:remoteSet];

    if ([toDelete count] > 0) {
        for (Blog *blog in account.blogs) {
            if ([toDelete containsObject:blog.dotComID]) {
                [self unscheduleBloggingRemindersFor:blog];
                // Consider switching this to a call to removeBlog in the future
                // to consolidate behaviour @frosty
                [context deleteObject:blog];
            }
        }
    }

    // Go through each remote incoming blog and make sure we're up to date with titles, etc.
    // Also adds any blogs we don't have
    for (RemoteBlog *remoteBlog in blogs) {
        [self updateBlogWithRemoteBlog:remoteBlog account:account inContext:context];
        [self updatePromptSettingsFor:remoteBlog context:context];
    }

    /*
     Sometimes bad things happen and blogs get duplicated. 👭
     Hopefully we'll fix all the causes and this should never happen again 🤞🤞🤞
     But even if it never happens again, it has already happened so we need to clean up. 🧹
     Otherwise, users would have to reinstall the app to get rid of duplicates 🙅‍♀️

     More context here:
     https://github.com/wordpress-mobile/WordPress-iOS/issues/7886#issuecomment-524221031
     */
    [account deduplicateBlogs];

    // Ensure that the account has a default blog defined (if there is one).
    AccountService *service = [[AccountService alloc] initWithCoreDataStack:self.coreDataStack];
    [service updateDefaultBlogIfNeeded:account inContext:context];
}

- (void)updateBlogWithRemoteBlog:(RemoteBlog *)remoteBlog account:(WPAccount *)account inContext:(NSManagedObjectContext *)context
{
    Blog *blog = [self findBlogWithDotComID:remoteBlog.blogID inAccount:account];

    if (!blog && remoteBlog.jetpack) {
        blog = [self migrateRemoteJetpackBlog:remoteBlog forAccount:account inContext:context];
    }

    if (!blog) {
        DDLogInfo(@"New blog from account %@: %@", account.username, remoteBlog);
        if (account != nil) {
            blog = [Blog createBlankBlogWithAccount:account];
        } else {
            blog = [Blog createBlankBlogInContext:context];
        }
        blog.xmlrpc = remoteBlog.xmlrpc;
    }

    [self updateBlog:blog withRemoteBlog:remoteBlog];
}

- (void)updateBlog:(Blog *)blog withRemoteBlog:(RemoteBlog *)remoteBlog
{
    [blog addSettingsIfNecessary];

    blog.url = remoteBlog.url;
    blog.dotComID = remoteBlog.blogID;
    blog.organizationID = remoteBlog.organizationID;
    blog.isHostedAtWPcom = !remoteBlog.jetpack;
    blog.icon = remoteBlog.icon;
    blog.capabilities = remoteBlog.capabilities;
    blog.isAdmin = remoteBlog.isAdmin;
    blog.visible = remoteBlog.visible;
    blog.options = remoteBlog.options;
    blog.planID = remoteBlog.planID;
    blog.planTitle = remoteBlog.planTitle;
    blog.planActiveFeatures = remoteBlog.planActiveFeatures;
    blog.hasPaidPlan = remoteBlog.hasPaidPlan;
    blog.quotaSpaceAllowed = remoteBlog.quotaSpaceAllowed;
    blog.quotaSpaceUsed = remoteBlog.quotaSpaceUsed;

    // Update 'Top Level' Settings
    BlogSettings *settings = blog.settings;
    settings.name = [remoteBlog.name stringByDecodingXMLCharacters];
    settings.tagline = [remoteBlog.tagline stringByDecodingXMLCharacters];
    
    [NSNotificationCenter.defaultCenter postNotificationName:WPBlogUpdatedNotification object:nil];
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
                         inContext:(NSManagedObjectContext *)context
{
    assert(remoteBlog.xmlrpc != nil);
    NSURL *xmlrpcURL = [NSURL URLWithString:remoteBlog.xmlrpc];
    NSURLComponents *components = [NSURLComponents componentsWithURL:xmlrpcURL resolvingAgainstBaseURL:NO];
    if ([components.scheme isEqualToString:@"https"]) {
        components.scheme = @"http";
    } else {
        components.scheme = @"https";
    }
    NSURL *alternateXmlrpcURL = components.URL;
    NSArray *blogsWithNoAccount = [Blog selfHostedInContext:context];
    Blog *jetpackBlog = [[blogsWithNoAccount wp_filter:^BOOL(Blog *blogToTest) {
        return [blogToTest.xmlrpc caseInsensitiveCompare:xmlrpcURL.absoluteString] == NSOrderedSame
        || [blogToTest.xmlrpc caseInsensitiveCompare:alternateXmlrpcURL.absoluteString] == NSOrderedSame;
    }] firstObject];

    if (jetpackBlog) {
        DDLogInfo(@"Migrating %@ to wp.com account %@", [jetpackBlog hostURL], account.username);
        jetpackBlog.account = account;
    }

    return jetpackBlog;
}

- (id<BlogServiceRemote>)remoteForBlog:(Blog *)blog
{
    id<BlogServiceRemote> remote;
    if ([blog supports:BlogFeatureWPComRESTAPI]) {
        if (blog.wordPressComRestApi) {
            remote = [[BlogServiceRemoteREST alloc] initWithWordPressComRestApi:blog.wordPressComRestApi siteID:blog.dotComID];
        }
    } else if (blog.xmlrpcApi) {
        remote = [[BlogServiceRemoteXMLRPC alloc] initWithApi:blog.xmlrpcApi username:blog.username password:blog.password];
    }

    return remote;
}

- (id<AccountServiceRemote>)remoteForAccount:(WPAccount *)account
{
    if (account.wordPressComRestApi == nil) {
        return nil;
    }

    return [[AccountServiceRemoteREST alloc] initWithWordPressComRestApi:account.wordPressComRestApi];
}

#pragma mark - Completion handlers

- (void)updateMultiAuthor:(NSArray<RemoteUser *> *)users forBlog:(NSManagedObjectID *)blogObjectID completionHandler:(void (^)(void))completion
{
    [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
        NSError *error;
        Blog *blog = (Blog *)[context existingObjectWithID:blogObjectID error:&error];
        if (error) {
            DDLogError(@"%@", error);
        }
        if (!blog) {
            return;
        }
        
        [self updateBlogAuthorsForBlog:blog withRemoteUsers:users inContext:context];
        
        blog.isMultiAuthor = users.count > 1;
        /// Search for a matching user ID
        /// - wp.com hosted: blog.account.userID
        /// - Jetpack: user.linkedUserID == blog.account.userID
        /// - self hosted: user.username == blog.username
        if (blog.account) {
            if ([blog isHostedAtWPcom]) {
                blog.userID = blog.account.userID;
            } else {
                for (RemoteUser *user in users) {
                    if ([user.linkedUserID isEqual:blog.account.userID]) {
                        blog.userID = user.userID;
                        break;
                    }
                }
            }
        } else if (blog.username != nil) {
            for (RemoteUser *user in users) {
                if ([user.username isEqualToString:blog.username]) {
                    blog.userID = user.userID;
                    break;
                }
            }
        }
    } completion: completion onQueue:dispatch_get_main_queue()];
}

- (BlogDetailsHandler)blogDetailsHandlerWithBlogObjectID:(NSManagedObjectID *)blogObjectID
                                       completionHandler:(void (^)(void))completion
{
    return ^void(RemoteBlog *remoteBlog) {
        [[[JetpackCapabilitiesService alloc] init] syncWithBlogs:@[remoteBlog] success:^(NSArray<RemoteBlog *> *blogs) {
            [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
                Blog *blog = (Blog *)[context existingObjectWithID:blogObjectID error:nil];
                if (blog) {
                    [self updateBlog:blog withRemoteBlog:blogs.firstObject];
                    [self updatePromptSettingsFor:blogs.firstObject context:context];
                }
            } completion:completion onQueue:dispatch_get_main_queue()];
        }];
    };
}

- (OptionsHandler)optionsHandlerWithBlogObjectID:(NSManagedObjectID *)blogObjectID
                               completionHandler:(void (^)(void))completion
{
    return ^void(NSDictionary *options) {
        [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
            Blog *blog = (Blog *)[context existingObjectWithID:blogObjectID error:nil];
            if (!blog) {
                return;
            }

            blog.options = [NSDictionary dictionaryWithDictionary:options];

            RemoteBlogSettings *remoteSettings = [RemoteBlogOptionsHelper remoteBlogSettingsFromXMLRPCDictionaryOptions:options];
            [self updateSettings:blog.settings withRemoteSettings:remoteSettings];


            // NOTE: `[blog version]` can return nil. If this happens `version` will be `0`
            CGFloat version = [[blog version] floatValue];
            if (version > 0 && version < [WordPressMinimumVersion floatValue]) {
                if (blog.lastUpdateWarning == nil
                    || [blog.lastUpdateWarning floatValue] < [WordPressMinimumVersion floatValue])
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        // TODO :: Remove UI call from service layer
                        [WPError showAlertWithTitle:NSLocalizedString(@"WordPress version too old", @"")
                                            message:[NSString stringWithFormat:NSLocalizedString(@"The site at %@ uses WordPress %@. We recommend to update to the latest version, or at least %@", @""), [blog hostname], [blog version], WordPressMinimumVersion]];
                    });
                    blog.lastUpdateWarning = WordPressMinimumVersion;
                }
            }
        } completion:completion onQueue:dispatch_get_main_queue()];
    };
}

- (PostFormatsHandler)postFormatsHandlerWithBlogObjectID:(NSManagedObjectID *)blogObjectID
                                       completionHandler:(void (^)(void))completion
{
    return ^void(NSDictionary *postFormats) {
        [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
            Blog *blog = (Blog *)[context existingObjectWithID:blogObjectID error:nil];
            if (blog) {
                NSDictionary *formats = postFormats;
                if (![formats objectForKey:PostFormatStandard]) {
                    NSMutableDictionary *mutablePostFormats = [formats mutableCopy];
                    mutablePostFormats[PostFormatStandard] = NSLocalizedString(@"Standard", @"Standard post format label");
                    formats = [NSDictionary dictionaryWithDictionary:mutablePostFormats];
                }
                blog.postFormats = formats;
            }
        } completion:completion onQueue:dispatch_get_main_queue()];
    };
}

- (void)updateSettings:(BlogSettings *)settings withRemoteSettings:(RemoteBlogSettings *)remoteSettings
{
    NSParameterAssert(settings);
    NSParameterAssert(remoteSettings);
    
    // Transformables
    NSSet *separatedBlocklistKeys = [remoteSettings.commentsBlocklistKeys uniqueStringComponentsSeparatedByNewline];
    NSSet *separatedModerationKeys = [remoteSettings.commentsModerationKeys uniqueStringComponentsSeparatedByNewline];
    
    // General
    settings.name = remoteSettings.name;
    settings.tagline = remoteSettings.tagline;
    settings.privacy = remoteSettings.privacy ?: settings.privacy;
    settings.languageID = remoteSettings.languageID ?: settings.languageID;
    settings.iconMediaID = remoteSettings.iconMediaID;
    settings.gmtOffset = remoteSettings.gmtOffset;
    settings.timezoneString = remoteSettings.timezoneString;
    
    // Writing
    settings.defaultCategoryID = remoteSettings.defaultCategoryID ?: settings.defaultCategoryID;
    settings.defaultPostFormat = remoteSettings.defaultPostFormat ?: settings.defaultPostFormat;
    settings.dateFormat = remoteSettings.dateFormat;
    settings.timeFormat = remoteSettings.timeFormat;
    settings.startOfWeek = remoteSettings.startOfWeek;
    settings.postsPerPage = remoteSettings.postsPerPage;

    // Discussion
    settings.commentsAllowed = [remoteSettings.commentsAllowed boolValue];
    settings.commentsBlocklistKeys = separatedBlocklistKeys;
    settings.commentsCloseAutomatically = [remoteSettings.commentsCloseAutomatically boolValue];
    settings.commentsCloseAutomaticallyAfterDays = remoteSettings.commentsCloseAutomaticallyAfterDays;
    settings.commentsFromKnownUsersAllowlisted = [remoteSettings.commentsFromKnownUsersAllowlisted boolValue];
    
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

    // AMP
    settings.ampSupported = [remoteSettings.ampSupported boolValue];
    settings.ampEnabled = [remoteSettings.ampEnabled boolValue];

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
    NSString *joinedBlocklistKeys = [[settings.commentsBlocklistKeys allObjects] componentsJoinedByString:@"\n"];
    NSString *joinedModerationKeys = [[settings.commentsModerationKeys allObjects] componentsJoinedByString:@"\n"];
    
    // General
    remoteSettings.name = settings.name;
    remoteSettings.tagline = settings.tagline;
    remoteSettings.privacy = settings.privacy;
    remoteSettings.languageID = settings.languageID;
    remoteSettings.iconMediaID = settings.iconMediaID;
    remoteSettings.gmtOffset = settings.gmtOffset;
    remoteSettings.timezoneString = settings.timezoneString;
    
    // Writing
    remoteSettings.defaultCategoryID = settings.defaultCategoryID;
    remoteSettings.defaultPostFormat = settings.defaultPostFormat;
    remoteSettings.dateFormat = settings.dateFormat;
    remoteSettings.timeFormat = settings.timeFormat;
    remoteSettings.startOfWeek = settings.startOfWeek;
    remoteSettings.postsPerPage = settings.postsPerPage;

    // Discussion
    remoteSettings.commentsAllowed = @(settings.commentsAllowed);
    remoteSettings.commentsBlocklistKeys = joinedBlocklistKeys;
    remoteSettings.commentsCloseAutomatically = @(settings.commentsCloseAutomatically);
    remoteSettings.commentsCloseAutomaticallyAfterDays = settings.commentsCloseAutomaticallyAfterDays;
    remoteSettings.commentsFromKnownUsersAllowlisted = @(settings.commentsFromKnownUsersAllowlisted);
    
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

    // AMP
    remoteSettings.ampEnabled = @(settings.ampEnabled);
    
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
