#import <Foundation/Foundation.h>
#import "LocalService.h"

@class WPAccount, Blog;

extern NSString *const WPAccountDefaultWordPressComAccountChangedNotification;

@interface AccountService : NSObject <LocalService>

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
 Removes the default WordPress.com account
 
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
 @param password the WordPress.com account's password
 @param authToken the OAuth2 token returned by signIntoWordPressDotComWithUsername:password:success:failure:
 @return a WordPress.com `WPAccount` object for the given `username`
 @see createOrUpdateWordPressComAccountWithUsername:password:authToken:context:
 */
- (WPAccount *)createOrUpdateWordPressComAccountWithUsername:(NSString *)username
                                                    password:(NSString *)password
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

///--------------------
/// @name Blog creation
///--------------------

/**
 Creates a `Blog` object for this account with the given XML-RPC dictionary
 
 If a there is an existing blog with the same `url`, it is returned as-is.
 
 @param blogInfo a dictionary containing `url`, `blogName`, `xmlrpc`, and `blogid`; as returned by `wp.getUsersBlogs`
 @return the newly created blog
 */
- (Blog *)findOrCreateBlogFromDictionary:(NSDictionary *)blogInfo withAccount:(WPAccount *)account;

- (void)syncBlogsForAccount:(WPAccount *)account success:(void (^)())success failure:(void (^)(NSError *error))failure;


@end
