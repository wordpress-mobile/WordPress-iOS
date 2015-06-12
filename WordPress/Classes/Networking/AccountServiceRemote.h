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
 *  @param      account     The account to get the details of.  Cannot be nil.
 *  @param      success     The block that will be executed on success.  Can be nil.
 *  @param      failure     The block that will be executed on failure.  Can be nil.
 */
- (void)getDetailsForAccount:(WPAccount *)account
                     success:(void (^)(RemoteUser *remoteUser))success
                     failure:(void (^)(NSError *error))failure;

@end
