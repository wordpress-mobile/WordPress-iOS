#import <Foundation/Foundation.h>
#import "LocalCoreDataService.h"

@class Blog, Post, Page, AbstractPost;

extern NSString * const PostServiceTypePost;
extern NSString * const PostServiceTypePage;
extern NSString * const PostServiceTypeAny;

@interface PostService : NSObject <LocalCoreDataService>

- (Post *)createDraftPostForBlog:(Blog *)blog;
- (Page *)createDraftPageForBlog:(Blog *)blog;

+ (Post *)createDraftPostInMainContextForBlog:(Blog *)blog;
+ (Page *)createDraftPageInMainContextForBlog:(Blog *)blog;

- (AbstractPost *)findPostWithID:(NSNumber *)postID inBlog:(Blog *)blog;

- (void)getPostWithID:(NSNumber *)postID
              forBlog:(Blog *)blog
              success:(void (^)(AbstractPost *post))success
              failure:(void (^)(NSError *))failure;

- (void)syncPostsOfType:(NSString *)postType
                forBlog:(Blog *)blog
                success:(void (^)())success
                failure:(void (^)(NSError *error))failure;

- (void)loadMorePostsOfType:(NSString *)postType
                    forBlog:(Blog *)blog
                    success:(void (^)())success
                    failure:(void (^)(NSError *error))failure;

- (void)syncPostsOfType:(NSString *)postType
           withStatuses:(NSArray *)postStatus
                forBlog:(Blog *)blog
                success:(void (^)(BOOL hasMore))success
                failure:(void (^)(NSError *))failure;

- (void)loadMorePostsOfType:(NSString *)postType
               withStatuses:(NSArray *)postStatus
                    forBlog:(Blog *)blog
                    success:(void (^)(BOOL hasMore))success
                    failure:(void (^)(NSError *))failure;

- (void)uploadPost:(AbstractPost *)post
           success:(void (^)())success
           failure:(void (^)(NSError *error))failure;

- (void)deletePost:(AbstractPost *)post
           success:(void (^)())success
           failure:(void (^)(NSError *error))failure;

- (void)trashPost:(AbstractPost *)post
          success:(void (^)())success
          failure:(void (^)(NSError *error))failure;

- (void)restorePost:(AbstractPost *)post
            success:(void (^)())success
            failure:(void (^)(NSError *error))failure;

@end
