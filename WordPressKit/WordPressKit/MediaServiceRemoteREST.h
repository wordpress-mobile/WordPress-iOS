#import <Foundation/Foundation.h>
#import "MediaServiceRemote.h"
#import "SiteServiceRemoteWordPressComREST.h"

NS_ASSUME_NONNULL_BEGIN

@interface MediaServiceRemoteREST : SiteServiceRemoteWordPressComREST <MediaServiceRemote>

- (RemoteMedia *)remoteMediaFromJSONDictionary:(NSDictionary *)jsonMedia;

- (void)uploadMedia:(nonnull RemoteMedia *)media
           progress:(NSProgress * __nullable __autoreleasing * __nullable)progress
    requestEnqueued:(nullable void (^)(void))requestEnqueued
            success:(nullable void (^)(RemoteMedia *remoteMedia))success
            failure:(nullable void (^)(NSError *error))failure;

@end

NS_ASSUME_NONNULL_END
