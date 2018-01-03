#import <Foundation/Foundation.h>
#import "MediaServiceRemote.h"
#import "SiteServiceRemoteWordPressComREST.h"

@interface MediaServiceRemoteREST : SiteServiceRemoteWordPressComREST <MediaServiceRemote>

/**
 Populates a RemoteMedia instance using values from a json dict returned
 from the endpoint.

 @param jsonMedia Media dictionary returned from the remote endpoint
 @return A RemoteMedia instance
 */
+ (RemoteMedia *)remoteMediaFromJSONDictionary:(NSDictionary *)jsonMedia;


/**
 Populates a array of RemoteMedia instances using an array of json dicts returned
 from the endpoint.

 @param jsonMedia An array of media dicts returned from the remote endpoint
 @return A array of RemoteMedia instances
 */
+ (NSArray *)remoteMediaFromJSONArray:(NSArray *)jsonMedia;

/**
 *  @brief      Upload multiple media items to the remote site.
 *
 *  @discussion This purpose of this method is to give app extensions the ability to upload media via background sessions.
 *
 *  @param  mediaItems      The media items to create remotely.
 *  @param  requestEnqueued The block that will be executed when the network request is queued.  Can be nil.
 *  @param  success         The block that will be executed on success.  Can be nil.
 *  @param  failure         The block that will be executed on failure.  Can be nil.
 */
- (void)uploadMedia:(NSArray *)mediaItems
    requestEnqueued:(void (^)(NSNumber *taskID))requestEnqueued
            success:(void (^)(NSArray *remoteMedia))success
            failure:(void (^)(NSError *error))failure;
@end
