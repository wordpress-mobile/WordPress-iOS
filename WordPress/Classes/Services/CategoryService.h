#import <Foundation/Foundation.h>
#import "LocalCoreDataService.h"

@class Category;

@interface CategoryService : NSObject <LocalCoreDataService>

- (Category *)newCategoryForBlogObjectID:(NSManagedObjectID *)blogObjectID;

- (Category *)findWithBlogObjectID:(NSManagedObjectID *)blogObjectID andCategoryID:(NSNumber *)categoryID;
- (Category *)findWithBlogObjectID:(NSManagedObjectID *)blogObjectID parentID:(NSNumber *)parentID andName:(NSString *)name;

- (void)createCategoryWithName:(NSString *)name
        parentCategoryObjectID:(NSManagedObjectID *)parentCategoryObjectID
               forBlogObjectID:(NSManagedObjectID *)blogObjectID
                       success:(void (^)(Category *category))success
                       failure:(void (^)(NSError *error))failure;

- (void)mergeNewCategories:(NSArray *)newCategories forBlogObjectID:(NSManagedObjectID *)blogObjectID;


@end
