#import <Foundation/Foundation.h>
#import "LocalCoreDataService.h"
#import "PostServiceOptions.h"

@class Blog, Post, Page, AbstractPost;

extern NSString * const PostServiceTypePost;
extern NSString * const PostServiceTypePage;
extern NSString * const PostServiceTypeAny;

extern const NSUInteger PostServiceDefaultNumberToSync;

typedef void(^PostServiceSyncSuccess)(NSArray *posts);
typedef void(^PostServiceSyncFailure)(NSError *error);

@interface PostService : LocalCoreDataService

- (Post *)createDraftPostForBlog:(Blog *)blog;
- (Page *)createDraftPageForBlog:(Blog *)blog;

+ (Post *)createDraftPostInMainContextForBlog:(Blog *)blog;
+ (Page *)createDraftPageInMainContextForBlog:(Blog *)blog;

- (AbstractPost *)findPostWithID:(NSNumber *)postID inBlog:(Blog *)blog;

/**
 Sync a specific post from the API

 @param postID The ID of the post to sync
 @param blog The blog that has the post.
 @param success A success block
 @param failure A failure block
 */
- (void)getPostWithID:(NSNumber *)postID
              forBlog:(Blog *)blog
              success:(void (^)(AbstractPost *post))success
              failure:(void (^)(NSError *))failure;

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
- (void)syncPostsOfType:(NSString *)postType
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
- (void)syncPostsOfType:(NSString *)postType
            withOptions:(PostServiceSyncOptions *)options
                forBlog:(Blog *)blog
                success:(PostServiceSyncSuccess)success
                failure:(PostServiceSyncFailure)failure;

/**
 Syncs local changes on a post back to the server.

 @param post The post or page to upload
 @param success A success block
 @param failure A failure block
 */
- (void)uploadPost:(AbstractPost *)post
           success:(void (^)())success
           failure:(void (^)(NSError *error))failure;

/**
 Attempts to delete the specified post outright vs moving it to the 
 trash folder.

 @param post The post or page to delete
 @param success A success block
 @param failure A failure block
 */
- (void)deletePost:(AbstractPost *)post
           success:(void (^)())success
           failure:(void (^)(NSError *error))failure;

/**
 Moves the specified post into the trash bin. Does not delete
 the post unless it was deleted on the server.

 @param post The post or page to trash
 @param success A success block
 @param failure A failure block
 */
- (void)trashPost:(AbstractPost *)post
          success:(void (^)())success
          failure:(void (^)(NSError *error))failure;


/**
 Moves the specified post out of the trash bin.

 @param post The post or page to restore
 @param success A success block
 @param failure A failure block
 */
- (void)restorePost:(AbstractPost *)post
           success:(void (^)())success
           failure:(void (^)(NSError *error))failure;

@end
