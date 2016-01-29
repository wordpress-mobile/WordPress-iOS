#import "LocalCoreDataService.h"

@class Blog;

@interface PostTagService : LocalCoreDataService

/* Fetches the associated tags for blog and replaces all currently persisted PostTag entities for blog.tags
 */
- (void)syncTagsForBlog:(Blog *)blog
                      success:(void (^)())success
                      failure:(void (^)(NSError *error))failure;

@end
