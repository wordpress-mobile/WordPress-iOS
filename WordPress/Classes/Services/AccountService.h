#import <Foundation/Foundation.h>
#import "CoreDataService.h"

NS_ASSUME_NONNULL_BEGIN

@class WPAccount;
@class RemoteUser;

extern NSString *const WPAccountDefaultWordPressComAccountChangedNotification;
extern NSNotificationName const WPAccountEmailAndDefaultBlogUpdatedNotification;

@interface AccountService : CoreDataService

///------------------------------------
/// @name Default WordPress.com account
///------------------------------------

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

/**
 Query to check if an email address is paired to a wpcom account. Used in the 
 magic links signup flow.

 @param email
 @param success
 @param failure
 */
- (void)isEmailAvailable:(NSString *)email success:(void (^)(BOOL available))success failure:(void (^)(NSError *error))failure;

/**
 Query to check if a username is available. Used in the signup flow.
 
 @param email
 @param success
 @param failure
 */
- (void)isUsernameAvailable:(NSString *)username
                    success:(void (^)(BOOL available))success
                    failure:(void (^)(NSError *error))failure;

/**
 Requests a verification email to be sent to the email address associated with the current account.

 @param success
 @param failure
 */
- (void)requestVerificationEmail:(void (^)(void))success
                         failure:(void (^)(NSError *error))failure;



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
 */
- (WPAccount *)createOrUpdateAccountWithUsername:(NSString *)username
                                       authToken:(NSString *)authToken
                                       inContext:(NSManagedObjectContext *)context;

- (NSUInteger)numberOfAccounts;

/**
 Returns all accounts currently existing in the main context.

 @return An array of WPAccounts.
 */
- (NSArray<WPAccount *> *)allAccounts;

/**
 Returns all accounts currently existing in core data.

 @return An array of WPAccounts.
 */
- (NSArray<WPAccount *> *)allAccountsInContext:(NSManagedObjectContext *)context;

/**
 Updates user details including username, email, userID, avatarURL, and default blog.

 @param account WPAccount to be updated
 */
- (void)updateUserDetailsForAccount:(WPAccount *)account
                            success:(nullable void (^)(void))success
                            failure:(nullable void (^)(NSError *error))failure;

/**
 Updates the default blog for the specified account.  The default blog will be the one whose siteID matches
 the accounts primaryBlogID.
 */
- (void)updateDefaultBlogIfNeeded:(WPAccount *)account;

/**
 Syncs the details for the account associated with the provided auth token, then
 creates or updates a WPAccount with the synced information.

 @param authToken The auth token associated with the account being created/updated.
 @param success A success block.
 @param failure A failure block.
 */
- (void)createOrUpdateAccountWithAuthToken:(NSString *)authToken
                                   success:(void (^)(WPAccount * _Nonnull))success
                                   failure:(void (^)(NSError * _Nonnull))failure;

/**
 Initializes the WordPress iOS Extensions with the WordPress.com Default Account.
 */
- (void)setupAppExtensionsWithDefaultAccount;


/**
 Removes an account if it's not the default account and there are no associated blogs
 */
- (void)purgeAccountIfUnused:(WPAccount *)account;

/**
 Restores a disassociated default WordPress.com account if the current defaultWordPressCom account is nil
 and another candidate account is found.  This method bypasses the normal setter to avoid triggering unintended
 side-effects from dispatching account changed notifications.
 */
- (void)restoreDisassociatedAccountIfNecessary;

///--------------------
/// @name Visible blogs
///--------------------

/**
 Sets the visibility for the given blogs
 */
- (void)setVisibility:(BOOL)visible forBlogs:(NSArray *)blogs;

@end

NS_ASSUME_NONNULL_END
