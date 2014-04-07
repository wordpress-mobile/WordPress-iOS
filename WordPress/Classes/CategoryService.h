#import <Foundation/Foundation.h>
#import "BaseLocalService.h"

@class Category;

@interface CategoryService : NSObject <LocalService>

- (BOOL)existsName:(NSString *)name forBlogObjectID:(NSManagedObjectID *)blogObjectID withParentId:(NSNumber *)parentId;

- (Category *)findWithBlogObjectID:(NSManagedObjectID *)blogObjectID andCategoryID:(NSNumber *)categoryID;

- (void)createCategoryWithName:(NSString *)name
        parentCategoryObjectID:(NSManagedObjectID *)parentCategoryObjectID
               forBlogObjectID:(NSManagedObjectID *)blogObjectID
                       success:(void (^)(Category *category))success
                       failure:(void (^)(NSError *error))failure;

- (void)mergeNewCategories:(NSArray *)newCategories forBlogObjectID:(NSManagedObjectID *)blogObjectID;


@end
