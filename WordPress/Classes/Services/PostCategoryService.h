#import <Foundation/Foundation.h>
#import "LocalCoreDataService.h"

@class Blog, PostCategory;

@interface PostCategoryService : NSObject <LocalCoreDataService>

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


@end
