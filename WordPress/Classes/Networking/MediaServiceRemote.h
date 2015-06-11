#import <Foundation/Foundation.h>

@class Blog;
@class RemoteMedia;

@protocol MediaServiceRemote <NSObject>

- (void) getMediaWithID:(NSNumber *) mediaID
                 forBlog:(Blog *)blog
                 success:(void (^)(RemoteMedia *remoteMedia))success
                 failure:(void (^)(NSError *error))failure;

- (void) createMedia:(RemoteMedia *)media
                forBlog:(Blog *)blog
               progress:(NSProgress **)progress
                success:(void (^)(RemoteMedia *remoteMedia))success
                failure:(void (^)(NSError *error))failure;

@end
