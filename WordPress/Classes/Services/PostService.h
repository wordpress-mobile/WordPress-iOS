#import <Foundation/Foundation.h>
#import "LocalCoreDataService.h"
#import "PostServiceOptions.h"

@class AbstractPost;
@class Blog;
@class Post;
@class Page;
@class RemotePost;
@class RemoteUser;
@class PostServiceRemoteFactory;
@class PostServiceSyncOptions;

NS_ASSUME_NONNULL_BEGIN

typedef void(^PostServiceSyncSuccess)(NSArray<AbstractPost *> * _Nullable posts);
typedef void(^PostServiceSyncFailure)(NSError * _Nullable error);

typedef NSString * PostServiceType NS_TYPED_ENUM;
extern PostServiceType const PostServiceTypePost;
extern PostServiceType const PostServiceTypePage;
extern PostServiceType const PostServiceTypeAny;
extern const NSUInteger PostServiceDefaultNumberToSync;


@interface PostService : LocalCoreDataService

// This is public so it can be accessed from Swift extensions.
@property (nonnull, strong, nonatomic) PostServiceRemoteFactory *postServiceRemoteFactory;

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context
                    postServiceRemoteFactory:(PostServiceRemoteFactory *)postServiceRemoteFactory NS_DESIGNATED_INITIALIZER;

/**
 Sync an initial batch of posts from the specified blog.
 Please note that success and/or failure are called in the context of the
 NSManagedObjectContext supplied when the PostService was initialized, and may not
 run on the main thread.

 @param postType The type (post or page) of post to sync
 @param blog The blog that has the posts.
 @param success A success block
 @param failure A failure block
 */
- (void)syncPostsOfType:(PostServiceType)postType
                forBlog:(Blog *)blog
                success:(PostServiceSyncSuccess)success
                failure:(PostServiceSyncFailure)failure;

/**
 Sync a batch of posts with the specified options from the specified blog.
 Please note that success and/or failure are called in the context of the
 NSManagedObjectContext supplied when the PostService was initialized, and may not
 run on the main thread.
 
 @param postType The type (post or page) of post to sync
 @param options Sync options for specific request parameters.
 @param blog The blog that has the posts.
 @param success A success block
 @param failure A failure block
 */
- (void)syncPostsOfType:(PostServiceType)postType
            withOptions:(PostServiceSyncOptions *)options
                forBlog:(Blog *)blog
                success:(PostServiceSyncSuccess)success
                failure:(PostServiceSyncFailure)failure;

@end

NS_ASSUME_NONNULL_END
