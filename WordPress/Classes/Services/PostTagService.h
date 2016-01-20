#import "LocalCoreDataService.h"

@class Blog;

@interface PostTagService : LocalCoreDataService

- (void)syncTagsForBlog:(Blog *)blog
                      success:(void (^)())success
                      failure:(void (^)(NSError *error))failure;

@end
