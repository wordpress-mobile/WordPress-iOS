#import <Foundation/Foundation.h>

@class Blog;

@interface CategoryServiceRemote : NSObject

- (void)createCategoryWithName:(NSString *)name
              parentCategoryID:(NSNumber *)parentCategoryID
                       forBlog:(Blog *)blog
                       success:(void (^)(NSNumber *categoryID))success
                       failure:(void (^)(NSError *error))failure;
@end
