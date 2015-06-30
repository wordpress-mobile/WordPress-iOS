#import <Foundation/Foundation.h>

@class Blog, RemotePost;

@protocol PostServiceRemote <NSObject>

- (void)getPostWithID:(NSNumber *)postID
              forBlog:(Blog *)blog
              success:(void (^)(RemotePost *post))success
              failure:(void (^)(NSError *))failure;

- (void)getPostsOfType:(NSString *)postType
               forBlog:(Blog *)blog
                success:(void (^)(NSArray *posts))success
                failure:(void (^)(NSError *error))failure;

- (void)getPostsOfType:(NSString *)postType
               forBlog:(Blog *)blog
               options:(NSDictionary *)options
               success:(void (^)(NSArray *posts))success
               failure:(void (^)(NSError *error))failure;

- (void)createPost:(RemotePost *)post
           forBlog:(Blog *)blog
           success:(void (^)(RemotePost *post))success
           failure:(void (^)(NSError *error))failure;

- (void)updatePost:(RemotePost *)post
           forBlog:(Blog *)blog
           success:(void (^)(RemotePost *post))success
           failure:(void (^)(NSError *error))failure;

- (void)deletePost:(RemotePost *)post
           forBlog:(Blog *)blog
           success:(void (^)())success
           failure:(void (^)(NSError *error))failure;

- (void)trashPost:(RemotePost *)post
          forBlog:(Blog *)blog
          success:(void (^)(RemotePost *))success
          failure:(void (^)(NSError *))failure;

- (void)restorePost:(RemotePost *)post
            forBlog:(Blog *)blog
            success:(void (^)(RemotePost *))success
            failure:(void (^)(NSError *error))failure;

@end