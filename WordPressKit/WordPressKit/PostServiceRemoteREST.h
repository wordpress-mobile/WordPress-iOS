#import <Foundation/Foundation.h>
#import "PostServiceRemote.h"
#import "SiteServiceRemoteWordPressComREST.h"
#import "RemoteMedia.h"

@interface PostServiceRemoteREST : SiteServiceRemoteWordPressComREST <PostServiceRemote>

/**
 *  @brief      Create a post remotely for the specified blog with a single piece of
 *              media.
 *
 *  @discussion This purpose of this method is to give app extensions the ability to create a post
 *              with media in a single network operation.
 *
 *  @param  post            The post to create remotely.  Cannot be nil.
 *  @param  media           The post to create remotely.  Can be nil.
 *  @param  requestEnqueued The block that will be executed when the network request is queued.  Can be nil.
 *  @param  success         The block that will be executed on success.  Can be nil.
 *  @param  failure         The block that will be executed on failure.  Can be nil.
 */
- (void)createPost:(RemotePost *)post
         withMedia:(RemoteMedia *)media
   requestEnqueued:(void (^)(NSNumber *taskID))requestEnqueued
           success:(void (^)(RemotePost *))success
           failure:(void (^)(NSError *))failure;

@end
