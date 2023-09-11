#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "PostService.h"

@class AbstractPost, RemotePost;

NS_ASSUME_NONNULL_BEGIN

@interface PostHelper: NSObject

+ (void)updatePost:(AbstractPost *)post withRemotePost:(RemotePost *)remotePost inContext:(NSManagedObjectContext *)managedObjectContext;

/**
 Creates a RemotePost from an AbstractPost to be used for API calls.

 @param post The AbstractPost used to create the RemotePost
 */
+ (RemotePost *)remotePostWithPost:(AbstractPost *)post;

@end

NS_ASSUME_NONNULL_END
