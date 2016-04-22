#import <Foundation/Foundation.h>
#import "LocalCoreDataService.h"

@class Blog;
@class PostCategory;

typedef NS_ENUM(NSInteger, PostCategoryServiceErrors) {
    PostCategoryServiceErrorsBlogNotFound
};

@interface PostCategoryService : LocalCoreDataService

- (PostCategory *)newCategoryForBlogObjectID:(NSManagedObjectID *)blogObjectID;

- (PostCategory *)findWithBlogObjectID:(NSManagedObjectID *)blogObjectID andCategoryID:(NSNumber *)categoryID;
- (PostCategory *)findWithBlogObjectID:(NSManagedObjectID *)blogObjectID parentID:(NSNumber *)parentID andName:(NSString *)name;

/** 
 Sync an initial batch of categories for blog via default remote parameters and responses.
 */
- (void)syncCategoriesForBlog:(Blog *)blog
                      success:(void (^)())success
                      failure:(void (^)(NSError *error))failure;

/**
 Sync an explicit number categories paginated by an offset for blog.
 */
- (void)syncCategoriesForBlog:(Blog *)blog
                       number:(NSNumber *)number
                       offset:(NSNumber *)offset
                      success:(void (^)(NSArray <PostCategory *> *categories))success
                      failure:(void (^)(NSError *error))failure;

/**
 Sync an initial batch of categories for blog via default remote parameters and responses.
 */
- (void)createCategoryWithName:(NSString *)name
        parentCategoryObjectID:(NSManagedObjectID *)parentCategoryObjectID
               forBlogObjectID:(NSManagedObjectID *)blogObjectID
                       success:(void (^)(PostCategory *category))success
                       failure:(void (^)(NSError *error))failure;
@end
