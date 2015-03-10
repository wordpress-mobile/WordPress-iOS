#import "BlogService.h"
#import "Blog.h"
#import "WPAccount.h"
#import "ContextManager.h"
#import "WPError.h"
#import "Comment.h"
#import "Post.h"
#import "Page.h"
#import "Media.h"
#import "CategoryService.h"
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
NSString *const BlogEntity = @"Blog";
NSString *const EditPostViewControllerLastUsedBlogURLOldKey = @"EditPostViewControllerLastUsedBlogURL";
NSString *const BlogName = @"blogName";
NSString *const IsVisiblePredicate = @"visible = YES";
NSString *const IsWPComAndVisiblePredicate = @"account.isWpcom = YES AND visible = YES";
NSString *const GetFeatures = @"wpcom.getFeatures";
NSString *const VideopressEnabled = @"videopress_enabled";
NSString *const XmlRpc = @"xmlrpc";
NSString *const Standard = @"standard";
NSString *const MinimumVersion = @"3.6";
NSString *const DateCreatedGmt = @"date_created_gmt";
NSString *const TimeZoneName = @"timezone";
NSString *const GmtOffset = @"gmt_offset";
NSString *const TimeZone = @"time_zone";
NSString *const HttpsPrefix = @"https://";

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
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:BlogEntity];
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
        NSString *oldKey = EditPostViewControllerLastUsedBlogURLOldKey;
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

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:BlogEntity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%@ AND url = %@", IsVisiblePredicate, url];
    [fetchRequest setPredicate:predicate];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:BlogName ascending:YES]];
    NSError *error = nil;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        DDLogError(@"Couldn't fetch blogs: %@", error);
        return nil;
    }

    if ([results count] == 0) {
        // Blog might have been removed from the app. Clear the key.
        [defaults removeObjectForKey:LastUsedBlogURLDefaultsKey];
        [defaults synchronize];
        return nil;
    }

    return [results firstObject];
}

- (Blog *)firstBlog
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:IsVisiblePredicate];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:BlogEntity];
    [fetchRequest setPredicate:predicate];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:BlogName ascending:YES]];
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
    NSPredicate *predicate = [NSPredicate predicateWithFormat:IsWPComAndVisiblePredicate];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:BlogEntity];
    [fetchRequest setPredicate:predicate];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:BlogName ascending:YES]];
    NSError *error = nil;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];

    if (error) {
        DDLogError(@"Couldn't fetch blogs: %@", error);
        return nil;
    }

    return [results firstObject];
}

- (void)syncBlogsForAccount:(WPAccount *)account success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    DDLogMethod();

    id<AccountServiceRemote> remote = [self remoteForAccount:account];
    [remote getBlogsWithSuccess:^(NSArray *blogs) {
        [self.managedObjectContext performBlock:^{
            [self mergeBlogs:blogs withAccount:account completion:success];
            
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

- (void)syncOptionsForBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    id<BlogServiceRemote> remote = [self remoteForBlog:blog];
    [remote syncOptionsForBlog:blog success:[self optionsHandlerWithBlogObjectID:blog.objectID completionHandler:success] failure:failure];
}

- (void)syncPostFormatsForBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    id<BlogServiceRemote> remote = [self remoteForBlog:blog];
    [remote syncPostFormatsForBlog:blog success:[self postFormatsHandlerWithBlogObjectID:blog.objectID completionHandler:success] failure:failure];
}

- (void)syncBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    if ([self shouldStaggerRequestsForBlog:blog]) {
        [self syncBlogStaggeringRequests:blog];
        return;
    }

    id<BlogServiceRemote> remote = [self remoteForBlog:blog];
    [remote syncOptionsForBlog:blog success:[self optionsHandlerWithBlogObjectID:blog.objectID completionHandler:nil] failure:^(NSError *error) {
        DDLogError(@"Failed syncing options for blog %@: %@", blog.url, error);
    }];
    [remote syncPostFormatsForBlog:blog success:[self postFormatsHandlerWithBlogObjectID:blog.objectID completionHandler:nil] failure:^(NSError *error) {
        DDLogError(@"Failed syncing post formats for blog %@: %@", blog.url, error);
    }];

    CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:self.managedObjectContext];
    // Right now, none of the callers care about the results of the sync
    // We're ignoring the callbacks here but this needs refactoring
    [commentService syncCommentsForBlog:blog success:nil failure:nil];

    CategoryService *categoryService = [[CategoryService alloc] initWithManagedObjectContext:self.managedObjectContext];
    [categoryService syncCategoriesForBlog:blog success:nil failure:nil];

    PostService *postService = [[PostService alloc] initWithManagedObjectContext:self.managedObjectContext];
    // FIXME: this is hacky, but XML-RPC doesn't support fetching "any" type of post
    // Ideally we'd do a multicall and fetch both posts/pages, but it's out of scope for this commit
    if (blog.restApi) {
        [postService syncPostsOfType:PostServiceTypeAny forBlog:blog success:nil failure:nil];
    } else {
        [postService syncPostsOfType:PostServiceTypePost forBlog:blog success:nil failure:nil];
        [postService syncPostsOfType:PostServiceTypePage forBlog:blog success:nil failure:nil];
    }
}

- (void)syncBlogStaggeringRequests:(Blog *)blog
{
    __weak __typeof(self) weakSelf = self;

    PostService *postService = [[PostService alloc] initWithManagedObjectContext:self.managedObjectContext];

    [postService syncPostsOfType:PostServiceTypePage forBlog:blog success:^{

        [postService syncPostsOfType:PostServiceTypePost forBlog:blog success:^{

            __strong __typeof(weakSelf) strongSelf = weakSelf;
            id<BlogServiceRemote> remote = [strongSelf remoteForBlog:blog];
            [remote syncOptionsForBlog:blog success:[strongSelf optionsHandlerWithBlogObjectID:blog.objectID completionHandler:nil] failure:^(NSError *error) {
                DDLogError(@"Failed syncing options for blog %@: %@", blog.url, error);
            }];
            [remote syncPostFormatsForBlog:blog success:[strongSelf postFormatsHandlerWithBlogObjectID:blog.objectID completionHandler:nil] failure:^(NSError *error) {
                DDLogError(@"Failed syncing post formats for blog %@: %@", blog.url, error);
            }];

            CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:strongSelf.managedObjectContext];
            // Right now, none of the callers care about the results of the sync
            // We're ignoring the callbacks here but this needs refactoring
            [commentService syncCommentsForBlog:blog success:nil failure:nil];

            CategoryService *categoryService = [[CategoryService alloc] initWithManagedObjectContext:strongSelf.managedObjectContext];
            [categoryService syncCategoriesForBlog:blog success:nil failure:nil];

        } failure:nil];

    } failure:nil];

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

- (void)checkVideoPressEnabledForBlog:(Blog *)blog success:(void (^)(BOOL enabled))success failure:(void (^)(NSError *error))failure
{
    if (!blog.isWPcom) {
        if (success) success(YES);
        return;
    }
    NSArray *parameters = [blog getXMLRPCArgsWithExtra:nil];
    WPXMLRPCRequest *request = [blog.api XMLRPCRequestWithMethod:GetFeatures parameters:parameters];
    WPXMLRPCRequestOperation *operation = [blog.api XMLRPCRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        BOOL videoEnabled = YES;
        if (([responseObject isKindOfClass:[NSDictionary class]]) && ([responseObject objectForKey:VideopressEnabled] != nil)) {
            videoEnabled = [[responseObject objectForKey:VideopressEnabled] boolValue];
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
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:BlogName ascending:YES];

    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:BlogEntity inManagedObjectContext:self.managedObjectContext]];
    [request setSortDescriptors:@[sortDescriptor]];

    NSError *error;
    NSArray *blogs = [self.managedObjectContext executeFetchRequest:request error:&error];

    if (error) {
        DDLogError(@"Error while retrieving all blogs");
        return nil;
    }

    return blogs;
}

///--------------------
/// @name Blog creation
///--------------------

- (Blog *)findBlogWithXmlrpc:(NSString *)xmlrpc inAccount:(WPAccount *)account
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
    Blog *blog = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Blog class]) inManagedObjectContext:self.managedObjectContext];
    blog.account = account;
    return blog;
}

#pragma mark - Private methods

- (void)mergeBlogs:(NSArray *)blogs withAccount:(WPAccount *)account completion:(void (^)())completion
{
    NSSet *remoteSet = [NSSet setWithArray:[blogs valueForKey:XmlRpc]];
    NSSet *localSet = [account.blogs valueForKey:XmlRpc];
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
        if (!blog && account.jetpackBlogs.count > 0) {
            blog = [self migrateRemoteJetpackBlog:remoteBlog forAccount:account];
        }
        if (!blog) {
            blog = [self createBlogWithAccount:account];
            blog.xmlrpc = remoteBlog.xmlrpc;
        }
        blog.url = remoteBlog.url;
        blog.blogName = [remoteBlog.title stringByDecodingXMLCharacters];
        blog.blogID = remoteBlog.ID;
        
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
- (Blog *)migrateRemoteJetpackBlog:(RemoteBlog *)remoteBlog forAccount:(WPAccount *)account
{
    Blog *jetpackBlog = [[account.jetpackBlogs filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        Blog *blogToTest = (Blog *)evaluatedObject;
        return [blogToTest.xmlrpc isEqualToString:remoteBlog.xmlrpc] && [blogToTest.dotComID isEqual:remoteBlog.ID];
    }]] anyObject];

    if (jetpackBlog) {
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

- (NSInteger)blogCountWithPredicate:(NSPredicate *)predicate
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:BlogEntity inManagedObjectContext:self.managedObjectContext]];
    [request setIncludesSubentities:NO];

    if (predicate) {
        [request setPredicate:predicate];
    }

    NSError *err;
    NSUInteger count = [self.managedObjectContext countForFetchRequest:request error:&err];
    if (count == NSNotFound) {
        count = 0;
    }
    return count;
}

- (NSUInteger)countForSyncedPostsWithEntityName:(NSString *)entityName forBlog:(Blog *)blog
{
    __block NSUInteger count = 0;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(remoteStatusNumber == %@) AND (postID != NULL) AND (original == NULL) AND (blog == %@)",
                              [NSNumber numberWithInt:AbstractPostRemoteStatusSync], blog];
    [request setPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:DateCreatedGmt ascending:YES];
    [request setSortDescriptors:@[sortDescriptor]];
    request.includesSubentities = NO;
    request.resultType = NSCountResultType;

    [self.managedObjectContext performBlockAndWait:^{
        NSError *error = nil;
        count = [self.managedObjectContext countForFetchRequest:request error:&error];
    }];
    return count;
}

#pragma mark - Completion handlers

- (OptionsHandler)optionsHandlerWithBlogObjectID:(NSManagedObjectID *)blogObjectID completionHandler:(void (^)(void))completion
{
    return ^void(NSDictionary *options) {
        [self.managedObjectContext performBlock:^{
            Blog *blog = (Blog *)[self.managedObjectContext existingObjectWithID:blogObjectID error:nil];
            if (blog) {
                blog.options = [NSDictionary dictionaryWithDictionary:options];
                float version = [[blog version] floatValue];
                if (version < [MinimumVersion floatValue]) {
                    if (blog.lastUpdateWarning == nil || [blog.lastUpdateWarning floatValue] < [MinimumVersion floatValue]) {
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

- (PostFormatsHandler)postFormatsHandlerWithBlogObjectID:(NSManagedObjectID *)blogObjectID completionHandler:(void (^)(void))completion
{
    return ^void(NSDictionary *postFormats) {
        [self.managedObjectContext performBlock:^{
            Blog *blog = (Blog *)[self.managedObjectContext existingObjectWithID:blogObjectID error:nil];
            if (blog) {
                NSDictionary *formats = postFormats;
                if (![formats objectForKey:Standard]) {
                    NSMutableDictionary *mutablePostFormats = [formats mutableCopy];
                    mutablePostFormats[Standard] = NSLocalizedString(Standard, @"Standard post format label");
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
    NSString *timeZoneName = [blog getOptionValue:TimeZoneName];
    NSNumber *gmtOffSet = [blog getOptionValue:GmtOffset];
    id optionValue = [blog getOptionValue:TimeZone];
    
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
    
    if (!timeZone) {
        timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    }
    
    return timeZone;
}

@end
