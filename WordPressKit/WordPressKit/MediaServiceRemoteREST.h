#import <Foundation/Foundation.h>
#import "MediaServiceRemote.h"
#import "SiteServiceRemoteWordPressComREST.h"

@interface MediaServiceRemoteREST : SiteServiceRemoteWordPressComREST <MediaServiceRemote>

+ (NSArray *)remoteMediaFromJSONArray:(NSArray *)jsonMedia;

+ (RemoteMedia *)remoteMediaFromJSONDictionary:(NSDictionary *)jsonMedia;

/**
 *  @brief      Upload a single media item to the remote site.
 *
 *  @discussion This purpose of this method is to give app extensions the ability to upload media via background sessions.
 *
 *  @param  media           The media item to create remotely.
 *  @param  requestEnqueued The block that will be executed when the network request is queued.  Can be nil.
 *  @param  success         The block that will be executed on success.  Can be nil.
 *  @param  failure         The block that will be executed on failure.  Can be nil.
 */
- (void)uploadMedia:(RemoteMedia *)media
    requestEnqueued:(void (^)(NSNumber *taskID))requestEnqueued
            success:(void (^)(RemoteMedia *remoteMedia))success
            failure:(void (^)(NSError *error))failure;

@end
