#import <Foundation/Foundation.h>
#import "LocalCoreDataService.h"

@class Blog, PostCategory;

@interface PostCategoryService : LocalCoreDataService

- (PostCategory *)newCategoryForBlogObjectID:(NSManagedObjectID *)blogObjectID;

- (PostCategory *)findWithBlogObjectID:(NSManagedObjectID *)blogObjectID andCategoryID:(NSNumber *)categoryID;
- (PostCategory *)findWithBlogObjectID:(NSManagedObjectID *)blogObjectID parentID:(NSNumber *)parentID andName:(NSString *)name;

- (void)syncCategoriesForBlog:(Blog *)blog
                      success:(void (^)())success
                      failure:(void (^)(NSError *error))failure;

- (void)createCategoryWithName:(NSString *)name
        parentCategoryObjectID:(NSManagedObjectID *)parentCategoryObjectID
               forBlogObjectID:(NSManagedObjectID *)blogObjectID
                       success:(void (^)(PostCategory *category))success
                       failure:(void (^)(NSError *error))failure;


/* Search categories for blog matching a name or slug of the query. Case-insensitive search.
 */
- (void)searchCategoriesWithName:(NSString *)nameQuery
                      blog:(Blog *)blog
                   success:(void (^)(NSArray <PostCategory *> *categories))success
                   failure:(void (^)(NSError *error))failure;

@end
