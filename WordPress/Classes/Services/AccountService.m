#import "AccountService.h"
#import "WPAccount.h"
#import "NotificationsManager.h"
#import "ContextManager.h"
#import "Blog.h"
#import "WPAnalyticsTrackerMixpanel.h"
#import "BlogService.h"
#import "TodayExtensionService.h"
#import "AccountServiceRemoteREST.h"

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

- (void)updateEmailAndDefaultBlogForWordPressComAccount:(WPAccount *)account
{
    if (!account) {
        return;
    }
    AccountServiceRemoteREST *remote = [[AccountServiceRemoteREST alloc] initWithApi:account.restApi];
    [remote getDetailsWithSuccess:^(NSDictionary *userDetails) {
        account.email = userDetails[@"email"];
        NSNumber *primaryBlogId = userDetails[@"primary_blog"];
        account.defaultBlog = [[account.blogs filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"blogID = %@", primaryBlogId]] anyObject];
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];

        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:WPAccountEmailAndDefaultBlogUpdatedNotification object:account];
        });
    } failure:^(NSError *error) {
        DDLogError(@"Failed to retrieve /me endpoint while updating email and default blog");
    }];
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

@end
