#import <Foundation/Foundation.h>
#import "RemoteUser.h"

@class WPAccount;

@protocol AccountServiceRemote <NSObject>

/**
 *  @brief      Gets an account's posts.
 *
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)getBlogsWithSuccess:(void (^)(NSArray *blogs))success
                    failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Gets an account's details.
 *
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)getAccountDetailsWithSuccess:(void (^)(RemoteUser *remoteUser))success
                             failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Updates blogs' visibility
 *
 *  @param      blogs       A dictionary with blog IDs as keys and a boolean indicating visibility as values.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)updateBlogsVisibility:(NSDictionary *)blogs
                      success:(void (^)())success
                      failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Query to see if an email address is paired with a wpcom acccount 
 *              or if it is available. Used in the auth link signup flow.
 *
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)isEmailAvailable:(NSString *)email
                 success:(void (^)(BOOL available))success
                 failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Query to see if a username is available. Used in the auth link signup flow.
 *  @note       This is an unversioned endpoint. Success will mean, generally, that the username already exists.
 *
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)isUsernameAvailable:(NSString *)username
                    success:(void (^)(BOOL available))success
                    failure:(void (^)(NSError *error))failure;

/**
*  @brief      Request an authentication link be sent to the email address provided.
*
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)requestWPComAuthLinkForEmail:(NSString *)email
                            clientID:(NSString *)clientID
                        clientSecret:(NSString *)clientSecret
                         wpcomScheme:(NSString *)scheme
                             success:(void (^)())success
                             failure:(void (^)(NSError *error))failure;
@end
