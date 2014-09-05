#import <Foundation/Foundation.h>
#import "LocalCoreDataService.h"

@class Blog, Post, Page, AbstractPost;

extern NSString * const PostServiceTypePost;
extern NSString * const PostServiceTypePage;

@interface PostService : NSObject <LocalCoreDataService>

- (Post *)createDraftPostForBlog:(Blog *)blog;
- (Page *)createDraftPageForBlog:(Blog *)blog;

- (void)syncPostsOfType:(NSString *)postType
                forBlog:(Blog *)blog
                success:(void (^)())success
                failure:(void (^)(NSError *error))failure;

- (void)loadMorePostsOfType:(NSString *)postType
                    forBlog:(Blog *)blog
                    success:(void (^)())success
                    failure:(void (^)(NSError *error))failure;

- (void)uploadPost:(AbstractPost *)post
           success:(void (^)())success
           failure:(void (^)(NSError *error))failure;

- (void)deletePost:(AbstractPost *)post
           success:(void (^)())success
           failure:(void (^)(NSError *error))failure;

@end
