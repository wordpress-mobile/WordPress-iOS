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
 *  This retrieves user details (email, username, userID, etc.) for a `WPAccount`.
 *
 *  @param account a valid WordPress.com account.
 */
- (void)updateUserDetailsForAccount:(WPAccount *)account
                            success:(void (^)())success
                            failure:(void (^)(NSError *error))failure;

/**
 *  This will set the default WordPress.com account to use.
 *
 *  @param account the WordPress.com account.
 */
-(void)setDefaultWordPressComAccount:(WPAccount *)account;

@end

/**
 *  This class handles some basic functions regarding a user's account.
 */
@interface AccountServiceFacade : NSObject<AccountServiceFacade>

@end
