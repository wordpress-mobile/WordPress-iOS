#import <Foundation/Foundation.h>

@class WPAccount;

/**
 *  This protocol represents a class that will handle some basic functions regarding
    a user's account.
 */
@protocol AccountServiceFacade

/**
 *  This creates a WordPress.com account.
 *
 *  @param username  WordPress.com username.
 *  @param authToken authToken to access account.
 *
 *  @return a newly created `WPAccount`.
 */
- (WPAccount *)createOrUpdateWordPressComAccountWithUsername:(NSString *)username
                                                   authToken:(NSString *)authToken;

/**
 *  This creates a self hosted account.
 *
 *  @param xmlrpc   xmlrpc url of the self hosted site.
 *  @param username username to access the self hosted site.
 *  @param password password to access the self hosted site.
 *
 *  @return a newly created `WPAccount`.
 */
- (WPAccount *)createOrUpdateSelfHostedAccountWithXmlrpc:(NSString *)xmlrpc
                                                username:(NSString *)username
                                             andPassword:(NSString *)password;


/**
 *  This retrieves user details (email, username, userID, etc.) for a `WPAccount`.
 *
 *  @param account a valid WordPress.com account.
 */
- (void)updateUserDetailsForAccount:(WPAccount *)account
                            success:(void (^)())success
                            failure:(void (^)(NSError *error))failure;

/**
 *  This will remove a previous legacy `WPAccount`.
 *
 *  @param newUsername username of the account to remove.
 */
-(void)removeLegacyAccount:(NSString *)newUsername;

@end

/**
 *  This class handles some basic functions regarding a user's account.
 */
@interface AccountServiceFacade : NSObject<AccountServiceFacade>

@end
