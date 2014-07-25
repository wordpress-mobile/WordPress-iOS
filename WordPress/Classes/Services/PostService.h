#import <Foundation/Foundation.h>
#import "LocalCoreDataService.h"

@class Blog, Post, Page;

@interface PostService : NSObject <LocalCoreDataService>

- (Post *)createDraftPostForBlog:(Blog *)blog;
- (Page *)createDraftPageForBlog:(Blog *)blog;

- (void)syncPostsForBlog:(Blog *)blog
                 success:(void (^)())success
                 failure:(void (^)(NSError *error))failure;

@end
