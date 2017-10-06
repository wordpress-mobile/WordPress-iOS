#import <Foundation/Foundation.h>
#import "LocalCoreDataService.h"

NS_ASSUME_NONNULL_BEGIN

@class Blog;
@class PostCategory;

typedef NS_ENUM(NSInteger, PostCategoryServiceErrors) {
    PostCategoryServiceErrorsBlogNotFound
};

@interface PostCategoryService : LocalCoreDataService

- (PostCategory *)newCategoryForBlogObjectID:(NSManagedObjectID *)blogObjectID;

- (nullable PostCategory *)findWithBlogObjectID:(NSManagedObjectID *)blogObjectID andCategoryID:(NSNumber *)categoryID;
- (nullable PostCategory *)findWithBlogObjectID:(NSManagedObjectID *)blogObjectID parentID:(nullable NSNumber *)parentID andName:(NSString *)name;

/** 
 Sync an initial batch of categories for blog via default remote parameters and responses.
 */
- (void)syncCategoriesForBlog:(Blog *)blog
                      success:(nullable void (^)(void))success
                      failure:(nullable void (^)(NSError *error))failure;

/**
 Sync an explicit number categories paginated by an offset for blog.
 */
- (void)syncCategoriesForBlog:(Blog *)blog
                       number:(nullable NSNumber *)number
                       offset:(nullable NSNumber *)offset
                      success:(nullable void (^)(NSArray <PostCategory *> *categories))success
                      failure:(nullable void (^)(NSError *error))failure;

/**
 Create a category for a remote blog with a name and optional parent category.
 */
- (void)createCategoryWithName:(NSString *)name
        parentCategoryObjectID:(nullable NSManagedObjectID *)parentCategoryObjectID
               forBlogObjectID:(NSManagedObjectID *)blogObjectID
                       success:(nullable void (^)(PostCategory *category))success
                       failure:(nullable void (^)(NSError *error))failure;
@end

NS_ASSUME_NONNULL_END
