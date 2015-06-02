#import <Foundation/Foundation.h>
#import "LocalCoreDataService.h"

@class WPAccount, Blog;

extern NSString *const WPAccountDefaultWordPressComAccountChangedNotification;
extern NSString *const WPAccountEmailAndDefaultBlogUpdatedNotification;

@interface AccountService : NSObject <LocalCoreDataService>

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
- (WPAccount *)defaultWordPressComAccount;

/**
 Sets the default WordPress.com account
 
 @param account the account to set as default for WordPress.com
 @see defaultWordPressComAccount
 @see removeDefaultWordPressComAccount
 */
- (void)setDefaultWordPressComAccount:(WPAccount *)account;

/**
 Removes the default WordPress.com account. Should only be called from the Main Thread
 
 @see defaultWordPressComAccount
 @see setDefaultWordPressComAccount:
 */
- (void)removeDefaultWordPressComAccount;

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
 @see createOrUpdateWordPressComAccountWithUsername:authToken:
 */
- (WPAccount *)createOrUpdateWordPressComAccountWithUsername:(NSString *)username
                                                   authToken:(NSString *)authToken;

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
                                             andPassword:(NSString *)password;


- (NSUInteger)numberOfAccounts;

/**
 Returns a WordPress.com account with the specified username, if it exists

 @param username the account's username
 @return a `WPAccount` object if there's one for the specified username. Otherwise it returns nil
 */
- (WPAccount *)findWordPressComAccountWithUsername:(NSString *)username;

/**
 Updates user details including username, email, userID, avatarURL, and default blog.

 @param account WPAccount to be updated
 */
- (void)updateUserDetailsForAccount:(WPAccount *)account success:(void (^)())success failure:(void (^)(NSError *error))failure;

/**
 Removes your default WordPress.com password from the keychain, if needed.
 */
- (void)removeWordPressComAccountPasswordIfNeeded;

/**
 Removes an account if it won't be used anymore.
 
 For self hosted accounts, the account will be removed if there are no associated blogs
 For WordPress.com accounts, the account will be removed if it's not the default account and there are no associated blogs
 */
- (void)purgeAccount:(WPAccount *)account;

@end
