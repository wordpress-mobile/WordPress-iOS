#import <Foundation/Foundation.h>

@class Blog, RemotePostCategory;

@protocol PostCategoryServiceRemote <NSObject>

- (void)getCategoriesForBlog:(Blog *)blog
                     success:(void (^)(NSArray *categories))success
                     failure:(void (^)(NSError *error))failure;

- (void)createCategory:(RemotePostCategory *)category
               forBlog:(Blog *)blog
               success:(void (^)(RemotePostCategory *category))success
               failure:(void (^)(NSError *error))failure;

@end