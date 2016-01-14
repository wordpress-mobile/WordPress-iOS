#import <Foundation/Foundation.h>
#import "LocalCoreDataService.h"

NS_ASSUME_NONNULL_BEGIN

@class WPAccount, Blog;

extern NSString *const WPAccountDefaultWordPressComAccountChangedNotification;
extern NSString *const WPAccountEmailAndDefaultBlogUpdatedNotification;

@interface AccountService : LocalCoreDataService

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
- (nullable WPAccount *)defaultWordPressComAccount;

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
 */
- (WPAccount *)createOrUpdateAccountWithUsername:(NSString *)username
                                       authToken:(NSString *)authToken;

- (NSUInteger)numberOfAccounts;

/**
 Returns a WordPress.com account with the specified username, if it exists

 @param username the account's username
 @return a `WPAccount` object if there's one for the specified username. Otherwise it returns nil
 */
- (nullable WPAccount *)findAccountWithUsername:(NSString *)username;

/**
 Returns a WordPress.com account with the specified user ID, if it exists

 @param userID the account's user ID
 @return a `WPAccount` object if there's one for the specified username. Otherwise it returns nil
 */
- (nullable WPAccount *)findAccountWithUserID:(NSNumber *)userID;

/**
 Updates user details including username, email, userID, avatarURL, and default blog.

 @param account WPAccount to be updated
 */
- (void)updateUserDetailsForAccount:(WPAccount *)account success:(void (^)())success failure:(void (^)(NSError *error))failure;

/**
 Removes an account if it won't be used anymore.
 
 For self hosted accounts, the account will be removed if there are no associated blogs
 For WordPress.com accounts, the account will be removed if it's not the default account and there are no associated blogs
 */
- (void)purgeAccount:(WPAccount *)account;

///--------------------
/// @name Visible blogs
///--------------------

/**
 Sets the visibility for the given blogs
 */
- (void)setVisibility:(BOOL)visible forBlogs:(NSArray *)blogs;

@end

NS_ASSUME_NONNULL_END