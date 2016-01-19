#import <Foundation/Foundation.h>

@class RemotePostCategory;
@class RemotePostTag;

@protocol TaxonomyServiceRemote <NSObject>

- (void)getCategoriesWithSuccess:(void (^)(NSArray <RemotePostCategory *> *categories))success
                         failure:(void (^)(NSError *error))failure;

- (void)createCategory:(RemotePostCategory *)category
               success:(void (^)(RemotePostCategory *category))success
               failure:(void (^)(NSError *error))failure;

- (void)getTagsWithSuccess:(void (^)(NSArray <RemotePostTag *> *tags))success
                   failure:(void (^)(NSError *error))failure;

@end