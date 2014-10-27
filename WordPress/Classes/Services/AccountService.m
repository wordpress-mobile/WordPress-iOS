#import "AccountService.h"
#import "WPAccount.h"
#import "NotificationsManager.h"
#import "ContextManager.h"
#import "Blog.h"
#import "AccountServiceRemote.h"
#import "AccountServiceRemoteREST.h"
#import "AccountServiceRemoteXMLRPC.h"
#import "WPAnalyticsTrackerMixpanel.h"
#import "BlogService.h"
#import "TodayExtensionService.h"

#import "NSString+XMLExtensions.h"

static NSString * const DefaultDotcomAccountUUIDDefaultsKey = @"AccountDefaultDotcomUUID";

@interface AccountService ()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

static NSString * const WordPressDotcomXMLRPCKey = @"https://wordpress.com/xmlrpc.php";
NSString * const WPAccountDefaultWordPressComAccountChangedNotification = @"WPAccountDefaultWordPressComAccountChangedNotification";

@implementation AccountService

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context
{
    self = [super init];
    if (self) {
        _managedObjectContext = context;
    }

    return self;
}

///------------------------------------
/// @name Default WordPress.com account
///------------------------------------

/**
 Returns the default WordPress.com account

 The default WordPress.com account is the one used for Reader and Notifications

 @return the default WordPress.com account
 @see setDefaultWordPressComAccount:
 @see removeDefaultWordPressComAccount
 */
- (WPAccount *)defaultWordPressComAccount
{
    NSString *uuid = [[NSUserDefaults standardUserDefaults] stringForKey:DefaultDotcomAccountUUIDDefaultsKey];
    if (uuid.length == 0) {
        return nil;
    }

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uuid == %@", uuid];
    fetchRequest.predicate = predicate;
    
    NSError *error = nil;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    WPAccount *defaultAccount = nil;
    if (fetchedObjects.count > 0) {
        defaultAccount = fetchedObjects.firstObject;
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:DefaultDotcomAccountUUIDDefaultsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    return defaultAccount;
}

/**
 Sets the default WordPress.com account

 @param account the account to set as default for WordPress.com
 @see defaultWordPressComAccount
 @see removeDefaultWordPressComAccount
 */
- (void)setDefaultWordPressComAccount:(WPAccount *)account
{
    NSParameterAssert(account != nil);
    NSAssert(account.isWpcom, @"account should be a wordpress.com account");
    NSAssert(account.authToken.length > 0, @"Account should have an authToken for WP.com");

    [[NSUserDefaults standardUserDefaults] setObject:account.uuid forKey:DefaultDotcomAccountUUIDDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:WPAccountDefaultWordPressComAccountChangedNotification object:account];

        [NotificationsManager registerForPushNotifications];
    });
}

/**
 Removes the default WordPress.com account

 @see defaultWordPressComAccount
 @see setDefaultWordPressComAccount:
 */
- (void)removeDefaultWordPressComAccount
{
    [NotificationsManager unregisterDeviceToken];

    WPAccount *account = [self defaultWordPressComAccount];
    if (account) {
        [self.managedObjectContext deleteObject:account];
    }

    [[ContextManager sharedInstance] saveContext:self.managedObjectContext withCompletionBlock:^{
        [WPAnalytics refreshMetadata];
        
        // Make sure this notification gets posted on the main thread: the managedObjectContext might be running
        // a private GCD queue, and we shouldn't really execute our own non-coredata code there.
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:WPAccountDefaultWordPressComAccountChangedNotification object:nil];
        });
    }];

    // Clear WordPress.com cookies
    NSArray *wpcomCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    for (NSHTTPCookie *cookie in wpcomCookies) {
        if ([cookie.domain hasSuffix:@"wordpress.com"]) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
        }
    }
    [[NSURLCache sharedURLCache] removeAllCachedResponses];

    [WPAnalyticsTrackerMixpanel resetEmailRetrievalCheck];

    // Remove defaults
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:DefaultDotcomAccountUUIDDefaultsKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"wpcom_username_preference"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"wpcom_users_blogs"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"wpcom_users_prefered_blog_id"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

///-----------------------
/// @name Account creation
///-----------------------

/**
 Creates a new WordPress.com account or updates the password if there is a matching account

 There can only be one WordPress.com account per username, so if one already exists for the given `username` its password is updated

 Uses a background managed object context.

 @param username the WordPress.com account's username
 @param password the WordPress.com account's password
 @param authToken the OAuth2 token returned by signIntoWordPressDotComWithUsername:password:success:failure:
 @return a WordPress.com `WPAccount` object for the given `username`
 @see createOrUpdateWordPressComAccountWithUsername:password:authToken:context:
 */
- (WPAccount *)createOrUpdateWordPressComAccountWithUsername:(NSString *)username
                                                    password:(NSString *)password
                                                   authToken:(NSString *)authToken
{
    WPAccount *account = [self createOrUpdateSelfHostedAccountWithXmlrpc:WordPressDotcomXMLRPCKey username:username andPassword:password];
    account.authToken = authToken;
    account.isWpcom = YES;
    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];

    if (![self defaultWordPressComAccount]) {
        [self setDefaultWordPressComAccount:account];
    }

    return account;
}

/**
 Creates a new self hosted account or updates the password if there is a matching account

 There can only be one account per XML-RPC endpoint and username, so if one already exists its password is updated

 @param xmlrpc the account XML-RPC endpoint
 @param username the account's username
 @param password the account's password
 @param context the NSManagedObjectContext used to create or update the account
 @return a `WPAccount` object for the given `xmlrpc` endpoint and `username`
 */
- (WPAccount *)createOrUpdateSelfHostedAccountWithXmlrpc:(NSString *)xmlrpc
                                                username:(NSString *)username
                                             andPassword:(NSString *)password
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"xmlrpc like %@ AND username like %@", xmlrpc, username]];
    [request setIncludesPendingChanges:YES];

    WPAccount *account;

    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:nil];
    if ([results count] > 0) {
        account = [results objectAtIndex:0];
    } else {
        account = [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:self.managedObjectContext];
        account.uuid = [[NSUUID new] UUIDString];
        account.xmlrpc = xmlrpc;
        account.username = username;
    }
    account.password = password;

    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];

    return account;

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
            if (!([b.url hasPrefix:@"https://"])) {
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
                BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:self.managedObjectContext];
                NSNumber *siteId = defaultBlog.blogID;
                NSString *blogName = defaultBlog.blogName;
                NSTimeZone *timeZone = [blogService timeZoneForBlog:defaultBlog];
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

#pragma mark - Private methods

- (void)mergeBlogs:(NSArray *)blogs withAccount:(WPAccount *)account completion:(void (^)())completion
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
        Blog *blog = [self findBlogWithXmlrpc:remoteBlog.xmlrpc inAccount:account];
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

- (id<AccountServiceRemote>)remoteForAccount:(WPAccount *)account
{
    if (account.restApi) {
        return [[AccountServiceRemoteREST alloc] initWithApi:account.restApi];
    }

    return [[AccountServiceRemoteXMLRPC alloc] initWithApi:account.xmlrpcApi];
}

- (NSUInteger)numberOfAccounts
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Account" inManagedObjectContext:self.managedObjectContext]];
    [request setIncludesSubentities:NO];

    NSError *error;
    NSUInteger count = [self.managedObjectContext countForFetchRequest:request error:&error];
    if (count == NSNotFound) {
        count = 0;
    }
    return count;
}

@end
