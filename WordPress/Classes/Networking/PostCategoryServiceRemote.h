#import <Foundation/Foundation.h>

@class RemotePostCategory;

@protocol PostCategoryServiceRemote <NSObject>

- (void)getCategoriesWithSuccess:(void (^)(NSArray *categories))success
                       failure:(void (^)(NSError *error))failure;

- (void)createCategory:(RemotePostCategory *)category
               success:(void (^)(RemotePostCategory *category))success
               failure:(void (^)(NSError *error))failure;

@end