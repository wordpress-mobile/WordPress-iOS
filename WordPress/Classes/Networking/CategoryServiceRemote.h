#import <Foundation/Foundation.h>

@class Blog, RemoteCategory;

@protocol CategoryServiceRemote <NSObject>

- (void)getCategoriesForBlog:(Blog *)blog
                     success:(void (^)(NSArray *categories))success
                     failure:(void (^)(NSError *error))failure;

- (void)createCategory:(RemoteCategory *)category
               forBlog:(Blog *)blog
               success:(void (^)(RemoteCategory *category))success
               failure:(void (^)(NSError *error))failure;

@end