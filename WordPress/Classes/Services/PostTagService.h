#import "LocalCoreDataService.h"

NS_ASSUME_NONNULL_BEGIN

@class Blog;
@class PostTag;

@interface PostTagService : LocalCoreDataService

/**
 Sync an initial batch of tags for blog via default remote parameters and responses.
 */
- (void)syncTagsForBlog:(Blog *)blog
                success:(nullable void (^)(NSArray <PostTag *> *tags))success
                failure:(nullable void (^)(NSError *error))failure;

/**
 Sync an explicit number tags paginated by an offset for blog.
 */
- (void)syncTagsForBlog:(Blog *)blog
                 number:(nullable NSNumber *)number
                 offset:(nullable NSNumber *)offset
                success:(nullable void (^)(NSArray <PostTag *> *tags))success
                failure:(nullable void (^)(NSError *error))failure;

/**
 Retrieves the most used tags for a blog.
 */
- (void)getTopTagsForBlog:(Blog *)blog
                  success:(nullable void (^)(NSArray <PostTag *> *tags))success
                  failure:(nullable void (^)(NSError *error))failure;

/**
 Search tags for blog matching a name or slug of the query. Case-insensitive search.
 */
- (void)searchTagsWithName:(NSString *)nameQuery
                      blog:(Blog *)blog
                   success:(nullable void (^)(NSArray <PostTag *> *tags))success
                   failure:(nullable void (^)(NSError *error))failure;


/**
 Deletes a tag assigned to a blog
 */
- (void)deleteTag:(PostTag*)tag
          forBlog:(Blog *)blog
          success:(nullable void (^)(void))success
          failure:(nullable void (^)(NSError *error))failure;

/**
 Saves a tag assigned to a blog
 */
- (void)saveTag:(PostTag*)tag
        forBlog:(Blog *)blog
        success:(nullable void (^)(PostTag *tag))success
        failure:(nullable void (^)(NSError *error))failure;
@end

NS_ASSUME_NONNULL_END
