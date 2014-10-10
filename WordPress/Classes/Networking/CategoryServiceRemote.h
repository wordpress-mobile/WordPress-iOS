#import <Foundation/Foundation.h>

@class Blog, RemoteCategory;

@protocol CategoryServiceRemote <NSObject>

- (void)createCategory:(RemoteCategory *)category
               forBlog:(Blog *)blog
               success:(void (^)(RemoteCategory *category))success
               failure:(void (^)(NSError *error))failure;

@end