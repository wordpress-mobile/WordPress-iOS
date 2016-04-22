#import "LocalCoreDataService.h"

@class Blog;
@class PostTag;

@interface PostTagService : LocalCoreDataService

/**
 Sync an initial batch of tags for blog via default remote parameters and responses.
 */
- (void)syncTagsForBlog:(Blog *)blog
                success:(void (^)())success
                failure:(void (^)(NSError *error))failure;

/**
 Sync an explicit number tags paginated by an offset for blog.
 */
- (void)syncTagsForBlog:(Blog *)blog
                 number:(NSNumber *)number
                 offset:(NSNumber *)offset
                success:(void (^)(NSArray <PostTag *> *tags))success
                failure:(void (^)(NSError *error))failure;

/**
 Search tags for blog matching a name or slug of the query. Case-insensitive search.
 */
- (void)searchTagsWithName:(NSString *)nameQuery
                      blog:(Blog *)blog
                   success:(void (^)(NSArray <PostTag *> *tags))success
                   failure:(void (^)(NSError *error))failure;

@end
