#import "AccountService.h"
#import "WPAccount.h"
#import "ContextManager.h"
#import "Blog.h"
#import "BlogService.h"
#import "TodayExtensionService.h"

@import WordPressKit;
@import WordPressShared;
#import "WordPress-Swift.h"

static NSString * const DefaultDotcomAccountUUIDDefaultsKey = @"AccountDefaultDotcomUUID";
static NSString * const DefaultDotcomAccountPasswordRemovedKey = @"DefaultDotcomAccountPasswordRemovedKey";

static NSString * const WordPressDotcomXMLRPCKey = @"https://wordpress.com/xmlrpc.php";
NSNotificationName const WPAccountDefaultWordPressComAccountChangedNotification = @"WPAccountDefaultWordPressComAccountChangedNotification";
NSString * const WPAccountEmailAndDefaultBlogUpdatedNotification = @"WPAccountEmailAndDefaultBlogUpdatedNotification";

@implementation AccountService

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
    if (uuid.length > 0) {
        WPAccount *account = [self accountWithUUID:uuid];
        if (account) {
            return account;
        }
    }

    // No account, or no default account set. Clear the defaults key.
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:DefaultDotcomAccountUUIDDefaultsKey];
    return nil;
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
    NSAssert(account.authToken.length > 0, @"Account should have an authToken for WP.com");

    if ([[self defaultWordPressComAccount] isEqual:account]) {
        return;
    }

    [[NSUserDefaults standardUserDefaults] setObject:account.uuid forKey:DefaultDotcomAccountUUIDDefaultsKey];

    NSManagedObjectID *accountID = account.objectID;
    void (^notifyAccountChange)(void) = ^{
        NSManagedObjectContext *mainContext = [[ContextManager sharedInstance] mainContext];
        NSManagedObject *accountInContext = [mainContext existingObjectWithID:accountID error:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:WPAccountDefaultWordPressComAccountChangedNotification object:accountInContext];

        [[PushNotificationsManager shared] registerForRemoteNotifications];
    };
    if ([NSThread isMainThread]) {
        // This is meant to help with testing account observers.
        // Short version: dispatch_async and XCTest asynchronous helpers don't play nice with each other
        // Long version: see the comment in https://github.com/wordpress-mobile/WordPress-iOS/blob/2f9a2100ca69d8f455acec47a1bbd6cbc5084546/WordPress/WordPressTest/AccountServiceRxTests.swift#L7
        notifyAccountChange();
    } else {
        dispatch_async(dispatch_get_main_queue(), notifyAccountChange);
    }
}

/**
 Removes the default WordPress.com account

 @see defaultWordPressComAccount
 @see setDefaultWordPressComAccount:
 */
- (void)removeDefaultWordPressComAccount
{
    NSAssert([NSThread isMainThread], @"This method should only be called from the main thread");

    [[PushNotificationsManager shared] unregisterDeviceToken];

    WPAccount *account = [self defaultWordPressComAccount];
    if (account == nil) {
        return;
    }
    [self.managedObjectContext deleteObject:account];

    [[ContextManager sharedInstance] saveContextAndWait:self.managedObjectContext];
    
    // Clear WordPress.com cookies
    NSArray<id<CookieJar>> *cookieJars = @[
        (id<CookieJar>)[NSHTTPCookieStorage sharedHTTPCookieStorage],
        (id<CookieJar>)[[WKWebsiteDataStore defaultDataStore] httpCookieStore]
    ];

    for (id<CookieJar> cookieJar in cookieJars) {
        [cookieJar removeWordPressComCookiesWithCompletion:^{}];
    }

    [[NSURLCache sharedURLCache] removeAllCachedResponses];

    // Remove defaults
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:DefaultDotcomAccountUUIDDefaultsKey];
    
    [WPAnalytics refreshMetadata];
    [[NSNotificationCenter defaultCenter] postNotificationName:WPAccountDefaultWordPressComAccountChangedNotification object:nil];
}

- (BOOL)isDefaultWordPressComAccount:(WPAccount *)account {
    NSString *uuid = [[NSUserDefaults standardUserDefaults] stringForKey:DefaultDotcomAccountUUIDDefaultsKey];
    if (uuid.length == 0) {
        return false;
    }
    return [account.uuid isEqualToString:uuid];
}

- (void)isEmailAvailable:(NSString *)email success:(void (^)(BOOL available))success failure:(void (^)(NSError *error))failure
{
    id<AccountServiceRemote> remote = [self remoteForAnonymous];
    [remote isEmailAvailable:email success:^(BOOL available) {
        if (success) {
            success(available);
        }
    } failure:^(NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)isUsernameAvailable:(NSString *)username
                    success:(void (^)(BOOL available))success
                    failure:(void (^)(NSError *error))failure
{
    id<AccountServiceRemote> remote = [self remoteForAnonymous];
    [remote isUsernameAvailable:username success:^(BOOL available) {
        if (success) {
            success(available);
        }
    } failure:^(NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)requestVerificationEmail:(void (^)(void))success failure:(void (^)(NSError * _Nonnull))failure
{
    id<AccountServiceRemote> remote = [self remoteForAccount:[self defaultWordPressComAccount]];
    [remote requestVerificationEmailWithSucccess:^{
        if (success) {
            success();
        }
    } failure:^(NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


///-----------------------
/// @name Account creation
///-----------------------

- (WPAccount *)createOrUpdateAccountWithUserDetails:(RemoteUser *)remoteUser authToken:(NSString *)authToken
{
    WPAccount *account = [self findAccountWithUserID:remoteUser.userID];
    if (account) {
        // Even if we find an account via its userID we should still update
        // its authtoken, otherwise the Authenticator's authtoken fixer won't
        // work.
        account.authToken = authToken;
    } else {
        NSString *username = remoteUser.username;
        account = [self createOrUpdateAccountWithUsername:username authToken:authToken];
    }
    [self updateAccount:account withUserDetails:remoteUser];
    return account;
}

/**
 Creates a new WordPress.com account or updates the password if there is a matching account

 There can only be one WordPress.com account per username, so if one already exists for the given `username` its password is updated

 Uses a background managed object context.

 @param username the WordPress.com account's username
 @param authToken the OAuth2 token returned by signIntoWordPressDotComWithUsername:authToken:
 @return a WordPress.com `WPAccount` object for the given `username`
 @see createOrUpdateWordPressComAccountWithUsername:password:authToken:
 */
- (WPAccount *)createOrUpdateAccountWithUsername:(NSString *)username
                                       authToken:(NSString *)authToken
{
    WPAccount *account = [self findAccountWithUsername:username];

    if (!account) {
        account = [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:self.managedObjectContext];
        account.uuid = [[NSUUID new] UUIDString];
        account.username = username;
    }
    account.authToken = authToken;
    [[ContextManager sharedInstance] saveContextAndWait:self.managedObjectContext];

    if (![self defaultWordPressComAccount]) {
        [self setDefaultWordPressComAccount:account];
        dispatch_async(dispatch_get_main_queue(), ^{
            [WPAnalytics refreshMetadata];
        });
    }

    return account;
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

- (NSArray<WPAccount *> *)allAccounts
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    NSError *error = nil;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        return @[];
    }
    return fetchedObjects;
}

/**
 Checks an account to see if it is just used to connect to Jetpack.

 @param account The account to inspect.
 @return True if used only for a Jetpack connection.
 */
- (BOOL)accountHasOnlyJetpackBlogs:(WPAccount *)account
{
    if ([account.blogs count] == 0) {
        // Most likly, this is a blogless account used for the reader or commenting and not Jetpack.
        return NO;
    }

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.isHostedAtWPcom = true"];
    NSSet *wpcomBlogs = [account.blogs filteredSetUsingPredicate:predicate];
    if ([wpcomBlogs count] > 0) {
        return NO;
    }

    return YES;
}

- (WPAccount *)accountWithUUID:(NSString *)uuid
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uuid == %@", uuid];
    fetchRequest.predicate = predicate;

    NSError *error = nil;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects.count > 0) {
        WPAccount *defaultAccount = fetchedObjects.firstObject;
        defaultAccount.displayName = [defaultAccount.displayName stringByDecodingXMLCharacters];
        return defaultAccount;
    }
    return nil;
}

- (void)restoreDisassociatedAccountIfNecessary
{
    if ([self defaultWordPressComAccount]) {
        return;
    }

    // Attempt to restore a default account that has somehow been disassociated.
    WPAccount *account = [self findDefaultAccountCandidate];
    if (account) {
        // Assume we have a good candidate account and make it the default account in the app.
        // Note that this should be the account with the most blogs.
        // Updates user defaults here vs the setter method to avoid potential side-effects from dispatched notifications.
        [[NSUserDefaults standardUserDefaults] setObject:account.uuid forKey:DefaultDotcomAccountUUIDDefaultsKey];
    }
}

- (WPAccount *)findDefaultAccountCandidate
{
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"blogs.@count" ascending:NO];
    NSArray *accounts = [[self allAccounts] sortedArrayUsingDescriptors:@[sort]];

    for (WPAccount *account in accounts) {
        // Skip accounts that were likely added to Jetpack-connected self-hosted
        // sites, while there was an existing default wpcom account.
        if ([self accountHasOnlyJetpackBlogs:account]) {
            continue;
        }
        return account;
    }
    return nil;
}

- (WPAccount *)findAccountWithUsername:(NSString *)username
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"username =[c] %@ || email =[c] %@", username, username]];
    [request setIncludesPendingChanges:YES];

    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:nil];
    return [results firstObject];
}

- (WPAccount *)findAccountWithUserID:(NSNumber *)userID
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"userID = %@", userID]];
    [request setIncludesPendingChanges:YES];

    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:nil];
    return [results firstObject];
}

- (void)createOrUpdateAccountWithAuthToken:(NSString *)authToken
                                   success:(void (^)(WPAccount * _Nonnull))success
                                   failure:(void (^)(NSError * _Nonnull))failure
{
    WordPressComRestApi *api = [WordPressComRestApi defaultApiWithOAuthToken:authToken userAgent:[WPUserAgent defaultUserAgent] localeKey:[WordPressComRestApi LocaleKeyDefault]];
    AccountServiceRemoteREST *remote = [[AccountServiceRemoteREST alloc] initWithWordPressComRestApi:api];
    [remote getAccountDetailsWithSuccess:^(RemoteUser *remoteUser) {
        WPAccount *account = [self createOrUpdateAccountWithUserDetails:remoteUser authToken:authToken];
        success(account);
    } failure:^(NSError *error) {
        failure(error);
    }];
}

- (void)updateUserDetailsForAccount:(WPAccount *)account
                           success:(nullable void (^)(void))success
                           failure:(nullable void (^)(NSError * _Nonnull))failure
{
    NSAssert(account, @"Account can not be nil");
    NSAssert(account.username, @"account.username can not be nil");

    NSString *username = account.username;
    id<AccountServiceRemote> remote = [self remoteForAccount:account];
    [remote getAccountDetailsWithSuccess:^(RemoteUser *remoteUser) {
        // account.objectID can be temporary, so fetch via username/xmlrpc instead.
        WPAccount *fetchedAccount = [self findAccountWithUsername:username];
        [self updateAccount:fetchedAccount withUserDetails:remoteUser];
        dispatch_async(dispatch_get_main_queue(), ^{
            [WPAnalytics refreshMetadata];
            if (success) {
                success();
            }
        });
    } failure:^(NSError *error) {
        DDLogError(@"Failed to fetch user details for account %@.  %@", account, error);
        if (failure) {
            failure(error);
        }
    }];
}

- (id<AccountServiceRemote>)remoteForAnonymous
{
    WordPressComRestApi *api = [WordPressComRestApi defaultApiWithOAuthToken:nil
                                                                   userAgent:nil
                                                                   localeKey:[WordPressComRestApi LocaleKeyDefault]];
    return [[AccountServiceRemoteREST alloc] initWithWordPressComRestApi:api];
}

- (id<AccountServiceRemote>)remoteForAccount:(WPAccount *)account
{
    if (account.wordPressComRestApi == nil) {
        return nil;
    }

    return [[AccountServiceRemoteREST alloc] initWithWordPressComRestApi:account.wordPressComRestApi];
}

- (void)updateAccount:(WPAccount *)account withUserDetails:(RemoteUser *)userDetails
{
    account.userID = userDetails.userID;
    account.username = userDetails.username;
    account.email = userDetails.email;
    account.avatarURL = userDetails.avatarURL;
    account.displayName = userDetails.displayName;
    account.dateCreated = userDetails.dateCreated;
    account.emailVerified = @(userDetails.emailVerified);
    account.primaryBlogID = userDetails.primaryBlogID;

    [self updateDefaultBlogIfNeeded: account];

    [[ContextManager sharedInstance] saveContextAndWait:self.managedObjectContext];
}

- (void)updateDefaultBlogIfNeeded:(WPAccount *)account
{
    if (!account.primaryBlogID || [account.primaryBlogID intValue] == 0) {
        return;
    }

    // Load the Default Blog
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"blogID = %@", account.primaryBlogID];
    Blog *defaultBlog = [[account.blogs filteredSetUsingPredicate:predicate] anyObject];

    if (!defaultBlog) {
        DDLogError(@"Error: The Default Blog could not be loaded");
        return;
    }

    // Setup the Account
    account.defaultBlog = defaultBlog;

    // Update app extensions if needed.
    if (account == [self defaultWordPressComAccount]) {
        [self setupAppExtensionsWithDefaultAccount];
    }
}

- (void)setupAppExtensionsWithDefaultAccount
{
    WPAccount *defaultAccount = [self defaultWordPressComAccount];
    Blog *defaultBlog = [defaultAccount defaultBlog];
    NSNumber *siteId    = defaultBlog.dotComID;
    NSString *blogName  = defaultBlog.settings.name;
    
    if (defaultBlog == nil || defaultBlog.isDeleted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            TodayExtensionService *service = [TodayExtensionService new];
            [service removeTodayWidgetConfiguration];

            [ShareExtensionService removeShareExtensionConfiguration];

            [NotificationSupportService deleteContentExtensionToken];
            [NotificationSupportService deleteServiceExtensionToken];
        });
    } else {
        // Required Attributes
        
        BlogService *blogService    = [[BlogService alloc] initWithManagedObjectContext:self.managedObjectContext];
        NSTimeZone *timeZone        = [blogService timeZoneForBlog:defaultBlog];
        NSString *oauth2Token       = defaultAccount.authToken;
        
        // For the Today Extension, if the user has set a non-primary site, use that.
        NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:WPAppGroupName];
        NSNumber *todayExtensionSiteID = [sharedDefaults objectForKey:WPStatsTodayWidgetUserDefaultsSiteIdKey];
        NSString *todayExtensionBlogName = [sharedDefaults objectForKey:WPStatsTodayWidgetUserDefaultsSiteNameKey];
        
        if (todayExtensionSiteID == NULL) {
            todayExtensionSiteID = siteId;
            todayExtensionBlogName = blogName;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            TodayExtensionService *service = [TodayExtensionService new];
            [service configureTodayWidgetWithSiteID:todayExtensionSiteID
                                           blogName:todayExtensionBlogName
                                       siteTimeZone:timeZone
                                     andOAuth2Token:oauth2Token];

            [ShareExtensionService configureShareExtensionDefaultSiteID:siteId.integerValue defaultSiteName:blogName];
            [ShareExtensionService configureShareExtensionToken:defaultAccount.authToken];
            [ShareExtensionService configureShareExtensionUsername:defaultAccount.username];

            [NotificationSupportService insertContentExtensionToken:defaultAccount.authToken];
            [NotificationSupportService insertContentExtensionUsername:defaultAccount.username];

            [NotificationSupportService insertServiceExtensionToken:defaultAccount.authToken];
            [NotificationSupportService insertServiceExtensionUsername:defaultAccount.username];
        });
    }
    
}

- (void)purgeAccountIfUnused:(WPAccount *)account
{
    NSParameterAssert(account);

    BOOL purge = NO;
    WPAccount *defaultAccount = [self defaultWordPressComAccount];
    if ([account.blogs count] == 0
        && ![defaultAccount isEqual:account]) {
        purge = YES;
    }

    if (purge) {
        DDLogWarn(@"Removing account since it has no blogs associated and it's not the default account: %@", account);
        [self.managedObjectContext deleteObject:account];
    }
}

///--------------------
/// @name Visible blogs
///--------------------

- (void)setVisibility:(BOOL)visible forBlogs:(NSArray *)blogs
{
    NSMutableDictionary *blogVisibility = [NSMutableDictionary dictionaryWithCapacity:blogs.count];
    for (Blog *blog in blogs) {
        NSAssert(blog.dotComID.unsignedIntegerValue > 0, @"blog should have a wp.com ID");
        NSAssert([blog.account isEqual:[self defaultWordPressComAccount]], @"blog should belong to the default account");
        // This shouldn't happen, but just in case, let's not crash if
        // something tries to change visibility for a self hosted
        if (blog.dotComID) {
            blogVisibility[blog.dotComID] = @(visible);
        }
        blog.visible = visible;
    }
    AccountServiceRemoteREST *remote = [self remoteForAccount:[self defaultWordPressComAccount]];
    [remote updateBlogsVisibility:blogVisibility success:nil failure:^(NSError *error) {
        DDLogError(@"Error setting blog visibility: %@", error);
    }];
}

@end
