#import <Foundation/Foundation.h>

@class Blog;

@interface CategoryServiceRemote : NSObject

- (id)initWithBlog:(Blog *)blog;

- (void)createCategoryWithName:(NSString *)name
              parentCategoryID:(NSNumber *)parentCategoryID
                       success:(void (^)(NSNumber *categoryID))success
                       failure:(void (^)(NSError *error))failure;

@end