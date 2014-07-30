#import <Foundation/Foundation.h>

@class Blog;

@protocol PostServiceRemote <NSObject>

- (void)getPostsForBlog:(Blog *)blog
                success:(void (^)(NSArray *posts))success
                failure:(void (^)(NSError *error))failure;

- (void)getPostsForBlog:(Blog *)blog
                options:(NSDictionary *)options
                success:(void (^)(NSArray *posts))success
                failure:(void (^)(NSError *error))failure;

@end