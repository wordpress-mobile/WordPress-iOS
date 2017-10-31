#import <Foundation/Foundation.h>
#import "RemoteUser.h"

@class WPAccount;

@protocol AccountServiceRemote <NSObject>

/**
 *  @brief      Gets all blogs for an account.
 *
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)getBlogsWithSuccess:(void (^)(NSArray *blogs))success
                    failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Gets only visible blogs for an account.
 *
 *  @discussion This method is designed for use in extensions in order to provide a simple
 *              way to retrieve a quick list of availible sites.
 *
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)getVisibleBlogsWithSuccess:(void (^)(NSArray *))success
                           failure:(void (^)(NSError *))failure;

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
                      success:(void (^)(void))success
                      failure:(void (^)(NSError *error))failure;

/**
 *  @brief      Query to check if a wpcom account requires a passwordless login option.
 *  @note       Note that if there is no acccount matching the supplied identifier
 *              the REST endpoing returns a 404 error code.
 *
 *  @param      identifier  May be an email address, username, or user ID.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)isPasswordlessAccount:(NSString *)identifier
                      success:(void (^)(BOOL passwordless))success
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
                             success:(void (^)(void))success
                             failure:(void (^)(NSError *error))failure;

 /**
  * @brief      Request to (re-)send the verification email for the current user.
  *
  *  @param      success     The block that will be executed on success.  Can be nil.
  *  @param      failure     The block that will be executed on failure.  Can be nil.
  */
- (void)requestVerificationEmailWithSucccess:(void (^)(void))success
                                     failure:(void (^)(NSError *error))failure;

@end
