#import <Foundation/Foundation.h>

@class Blog;

@protocol PostServiceRemote <NSObject>

- (void)getPostsForBlog:(Blog *)blog
                success:(void (^)(NSArray *posts))success
                failure:(void (^)(NSError *error))failure;

@end