#import <Foundation/Foundation.h>
#import "RemoteComment.h"

@class Blog;

@protocol CommentServiceRemote <NSObject>

- (void)getCommentsForBlog:(Blog *)blog
                   success:(void (^)(NSArray *comments))success
                   failure:(void (^)(NSError *error))failure;


@end
