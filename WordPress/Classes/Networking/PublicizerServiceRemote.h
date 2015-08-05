#import <Foundation/Foundation.h>
#import "ServiceRemoteREST.h"

@class Blog;

@interface PublicizerServiceRemote : ServiceRemoteREST

/**
 *  @brief      Gets list of Publicize services available.
 *
 *  @param      success     The success handler.  Can be nil.
 *  @param      failure     The failure handler.  Can be nil.
 */
- (void)getPublicizersWithSuccess:(void (^)(NSArray *publicizers))success
                          failure:(void (^)(NSError *error))failure;

@end
