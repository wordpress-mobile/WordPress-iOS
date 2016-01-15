#import <Foundation/Foundation.h>

@class RemotePostCategory;

@protocol PostCategoryServiceRemote <NSObject>

- (void)getCategoriesForBlogID:(NSNumber *)blogID
                       success:(void (^)(NSArray *categories))success
                       failure:(void (^)(NSError *error))failure;

- (void)createCategory:(RemotePostCategory *)category
             forBlogID:(NSNumber *)blogID
               success:(void (^)(RemotePostCategory *category))success
               failure:(void (^)(NSError *error))failure;

@end