#import "AccountService.h"
#import "WPAccount.h"
#import "NotificationsManager.h"
#import "ContextManager.h"
#import "Blog.h"
#import "WPAnalyticsTrackerMixpanel.h"
#import "BlogService.h"
#import "TodayExtensionService.h"
#import "AccountServiceRemoteREST.h"
#import "AccountServiceRemoteXMLRPC.h"

#import "NSString+Helpers.h"
#import "NSString+XMLExtensions.h"

static NSString * const DefaultDotcomAccountUUIDDefaultsKey = @"AccountDefaultDotcomUUID";
static NSString * const DefaultDotcomAccountPasswordRemovedKey = @"DefaultDotcomAccountPasswordRemovedKey";

@interface AccountService ()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

static NSString * const WordPressDotcomXMLRPCKey = @"https://wordpress.com/xmlrpc.php";
NSString * const WPAccountDefaultWordPressComAccountChangedNotification = @"WPAccountDefaultWordPressComAccountChangedNotification";
NSString * const WPAccountEmailAndDefaultBlogUpdatedNotification = @"WPAccountEmailAndDefaultBlogUpdatedNotification";

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
    NSAssert([NSThread isMainThread], @"This method should only be called from the main thread");
    
    [NotificationsManager unregisterDeviceToken];

    WPAccount *account = [self defaultWordPressComAccount];
    if (account) {
        [self.managedObjectContext deleteObject:account];
    }

    [[ContextManager sharedInstance] saveContextAndWait:self.managedObjectContext];
    
    // Clear WordPress.com cookies
    NSArray *wpcomCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    for (NSHTTPCookie *cookie in wpcomCookies) {
        if (cookie.domain.isWordPressComPath) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
        }
    }
    [[NSURLCache sharedURLCache] removeAllCachedResponses];

    // Remove defaults
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:DefaultDotcomAccountUUIDDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [WPAnalytics refreshMetadata];
    [[NSNotificationCenter defaultCenter] postNotificationName:WPAccountDefaultWordPressComAccountChangedNotification object:nil];

}

///-----------------------
/// @name Account creation
///-----------------------

/**
 Creates a new WordPress.com account or updates the password if there is a matching account

 There can only be one WordPress.com account per username, so if one already exists for the given `username` its password is updated

 Uses a background managed object context.

 @param username the WordPress.com account's username
 @param authToken the OAuth2 token returned by signIntoWordPressDotComWithUsername:authToken:
 @return a WordPress.com `WPAccount` object for the given `username`
 @see createOrUpdateWordPressComAccountWithUsername:password:authToken:
 */
- (WPAccount *)createOrUpdateWordPressComAccountWithUsername:(NSString *)username
                                                   authToken:(NSString *)authToken
{
    WPAccount *account = [self createOrUpdateSelfHostedAccountWithXmlrpc:WordPressDotcomXMLRPCKey username:username andPassword:nil];
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
    WPAccount *account = [self findAccountWithUsername:username andXmlrpc:xmlrpc];

    if (!account) {
        account = [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:self.managedObjectContext];
        account.uuid = [[NSUUID new] UUIDString];
        account.xmlrpc = xmlrpc;
        account.username = username;
    }
    account.password = password;

    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];

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

- (WPAccount *)findWordPressComAccountWithUsername:(NSString *)username
{
    return [self findAccountWithUsername:username andXmlrpc:WordPressDotcomXMLRPCKey];
}

- (WPAccount *)findAccountWithUsername:(NSString *)username andXmlrpc:(NSString *)xmlrpc
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"xmlrpc like %@ AND username like %@", xmlrpc, username]];
    [request setIncludesPendingChanges:YES];

    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:nil];
    return [results firstObject];
}

- (void)removeWordPressComAccountPasswordIfNeeded
{
    // Let's do this just once!
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:DefaultDotcomAccountPasswordRemovedKey]) {
        return;
    }
    
    WPAccount *account = [self defaultWordPressComAccount];
    account.password = nil;
    
    [defaults setBool:YES forKey:DefaultDotcomAccountPasswordRemovedKey];
    [defaults synchronize];
}

- (void)updateUserDetailsForAccount:(WPAccount *)account success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    NSAssert(account, @"Account can not be nil");
    NSAssert(account.username, @"account.username can not be nil");
    NSAssert(account.xmlrpc, @"account.xmlrpc can not be nil");

    NSString *username = account.username;
    NSString *xmlrpc = account.xmlrpc;
    id<AccountServiceRemote> remote = [self remoteForAccount:account];
    [remote getDetailsForAccount:account success:^(RemoteUser *remoteUser) {
        // account.objectID can be temporary, so fetch via username/xmlrpc instead.
        WPAccount *fetchedAccount = [self findAccountWithUsername:username andXmlrpc:xmlrpc];
        [self updateAccount:fetchedAccount withUserDetails:remoteUser];
        dispatch_async(dispatch_get_main_queue(), ^{
            [WPAnalytics refreshMetadata];
        });
        if (success) {
            success();
        }
    } failure:^(NSError *error) {
        DDLogError(@"Failed to fetch user details for account %@.  %@", account, error);
        if (failure) {
            failure(error);
        }
    }];
}

- (id<AccountServiceRemote>)remoteForAccount:(WPAccount *)account
{
    if (account.restApi) {
        return [[AccountServiceRemoteREST alloc] initWithApi:account.restApi];
    }
    return [[AccountServiceRemoteXMLRPC alloc] initWithApi:account.xmlrpcApi];
}

- (void)updateAccount:(WPAccount *)account withUserDetails:(RemoteUser *)userDetails
{
    account.userID = userDetails.userID;
    account.username = userDetails.username;
    account.email = userDetails.email;
    account.avatarURL = userDetails.avatarURL;
    if (userDetails.primaryBlogID) {
        account.defaultBlog = [[account.blogs filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"blogID = %@", userDetails.primaryBlogID]] anyObject];
    }
    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
}

- (void)purgeAccount:(WPAccount *)account
{
    NSParameterAssert(account);

    BOOL purge = NO;
    if (account.isWpcom) {
        WPAccount *defaultAccount = [self defaultWordPressComAccount];
        if ([account.jetpackBlogs count] == 0
            && ![defaultAccount isEqual:account]) {
            purge = YES;
        }
    } else {
        if ([account.blogs count] == 0) {
            purge = YES;
        }
    }

    if (purge) {
        DDLogWarn(@"Removing account since it has no blogs associated and it's not the default account: %@", account);
        [self.managedObjectContext deleteObject:account];
    }
}

@end
