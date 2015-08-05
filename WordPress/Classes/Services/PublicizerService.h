#import <Foundation/Foundation.h>
#import "LocalCoreDataService.h"

@class Blog;

@interface PublicizerService : LocalCoreDataService

/**
 *  @brief      Updates blog list of Publicize services available.
 *
 *  @param      blog        The blog to update.
 *  @param      success     The success handler.  Can be nil.
 *  @param      failure     The failure handler.  Can be nil.
 */
- (void)syncPublicizersForBlog:(Blog *)blog
                       success:(void (^)())success
                       failure:(void (^)(NSError *error))failure;

@end
