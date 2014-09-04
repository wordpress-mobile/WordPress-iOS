#import <Foundation/Foundation.h>

@class Blog, RemotePost;

@protocol PostServiceRemote <NSObject>

- (void)getPostsForBlog:(Blog *)blog
                success:(void (^)(NSArray *posts))success
                failure:(void (^)(NSError *error))failure;

- (void)getPostsForBlog:(Blog *)blog
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


@end