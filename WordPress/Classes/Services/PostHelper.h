#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "PostService.h"

@class AbstractPost, RemotePost;

NS_ASSUME_NONNULL_BEGIN

@interface PostService (PostHelper)

- (void)updatePost:(AbstractPost *)post withRemotePost:(RemotePost *)remotePost;

@end

NS_ASSUME_NONNULL_END
