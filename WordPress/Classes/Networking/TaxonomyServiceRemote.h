#import <Foundation/Foundation.h>

@class RemotePostCategory;
@class RemotePostTag;

/*
 Interface for requesting taxonomy such as tags and categories on a site.
 */
@protocol TaxonomyServiceRemote <NSObject>

/* Fetch a list of categories associated with the site.
 */
- (void)getCategoriesWithSuccess:(void (^)(NSArray <RemotePostCategory *> *categories))success
                         failure:(void (^)(NSError *error))failure;

/* Create a new category with the site.
 */
- (void)createCategory:(RemotePostCategory *)category
               success:(void (^)(RemotePostCategory *category))success
               failure:(void (^)(NSError *error))failure;

/* Fetch a list of tags associated with the site.
 */
- (void)getTagsWithSuccess:(void (^)(NSArray <RemotePostTag *> *tags))success
                   failure:(void (^)(NSError *error))failure;

@end