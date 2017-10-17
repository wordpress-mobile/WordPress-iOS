#import <Foundation/Foundation.h>
#import "PostServiceRemote.h"
#import "SiteServiceRemoteWordPressComREST.h"
#import "RemoteMedia.h"

@interface PostServiceRemoteREST : SiteServiceRemoteWordPressComREST <PostServiceRemote>

- (void)createPost:(RemotePost *)post
         withMedia:(RemoteMedia *)media
           success:(void (^)(RemotePost *))success
           failure:(void (^)(NSError *))failure;

@end
