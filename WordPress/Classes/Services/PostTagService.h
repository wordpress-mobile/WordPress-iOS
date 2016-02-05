#import "LocalCoreDataService.h"

@class Blog;
@class PostTag;

@interface PostTagService : LocalCoreDataService

/* Sync an initial batch of tags for blog via default remote parameters and responses.
 */
- (void)syncTagsForBlog:(Blog *)blog
                success:(void (^)())success
                failure:(void (^)(NSError *error))failure;

/* Sync additional tags for blog via paging maintained within an instance of PostTagService.
 */
- (void)loadMoreTagsForBlog:(Blog *)blog
                    success:(void (^)(NSArray <PostTag *> *tags))success
                    failure:(void (^)(NSError *error))failure;

/* Search tags for blog matching a name or slug of the query. Case-insensitive search.
 */
- (void)searchTagsWithName:(NSString *)nameQuery
                      blog:(Blog *)blog
                   success:(void (^)(NSArray <PostTag *> *tags))success
                   failure:(void (^)(NSError *error))failure;

@end
