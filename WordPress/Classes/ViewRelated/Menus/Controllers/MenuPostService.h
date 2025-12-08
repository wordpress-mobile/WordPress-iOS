#import <Foundation/Foundation.h>

@import WordPressData;

@class AbstractPost;
@class Blog;
@class Post;
@class Page;
@class RemotePost;
@class RemoteUser;
@class PostServiceRemoteFactory;
@class MenuPostServiceSyncOptions;

NS_ASSUME_NONNULL_BEGIN

typedef void(^PostServiceSyncSuccess)(NSArray<AbstractPost *> * _Nullable posts);
typedef void(^PostServiceSyncFailure)(NSError * _Nullable error);

extern const NSUInteger PostServiceDefaultNumberToSync;

@interface MenuPostService : LocalCoreDataService

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
            withOptions:(MenuPostServiceSyncOptions *)options
                forBlog:(Blog *)blog
                success:(PostServiceSyncSuccess)success
                failure:(PostServiceSyncFailure)failure;

@end

NS_ASSUME_NONNULL_END
