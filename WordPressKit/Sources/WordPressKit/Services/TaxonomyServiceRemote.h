#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RemotePostCategory;
@class RemotePostTag;
@class RemoteTaxonomyPaging;

/**
 Interface for requesting taxonomy such as tags and categories on a site.
 */
@protocol TaxonomyServiceRemote <NSObject>

/**
 Create a new category with the site.
 */
- (void)createCategory:(RemotePostCategory *)category
               success:(nullable void (^)(RemotePostCategory *category))success
               failure:(nullable void (^)(NSError *error))failure;

/**
 Fetch a list of categories associated with the site.
 Note: Requests no paging parameters via the API defaulting the response.
 */
- (void)getCategoriesWithSuccess:(void (^)(NSArray <RemotePostCategory *> *categories))success
                         failure:(nullable void (^)(NSError *error))failure;

/**
 Fetch a list of categories associated with the site with paging.
 */
- (void)getCategoriesWithPaging:(RemoteTaxonomyPaging *)paging
                        success:(void (^)(NSArray <RemotePostCategory *> *categories))success
                        failure:(nullable void (^)(NSError *error))failure;

/**
 Fetch a list of categories whose names or slugs match the provided search query. Case-insensitive.
 */
- (void)searchCategoriesWithName:(NSString *)nameQuery
                         success:(void (^)(NSArray <RemotePostCategory *> *categories))success
                         failure:(nullable void (^)(NSError *error))failure;

/**
 Create a new tag with the site.
 */
- (void)createTag:(RemotePostTag *)tag
          success:(nullable void (^)(RemotePostTag *tag))success
          failure:(nullable void (^)(NSError *error))failure;

/**
 Update a tag with the site.
 */
- (void)updateTag:(RemotePostTag *)tag
		  success:(nullable void (^)(RemotePostTag *tag))success
		  failure:(nullable void (^)(NSError *error))failure;

/**
 Delete a tag with the site.
 */
- (void)deleteTag:(RemotePostTag *)tag
		  success:(nullable void (^)(void))success
		  failure:(nullable void (^)(NSError *error))failure;

/**
 Fetch a list of tags associated with the site.
 Note: Requests no paging parameters via the API defaulting the response.
 */
- (void)getTagsWithSuccess:(void (^)(NSArray <RemotePostTag *> *tags))success
                   failure:(nullable void (^)(NSError *error))failure;

/**
 Fetch a list of tags associated with the site with paging.
 */
- (void)getTagsWithPaging:(RemoteTaxonomyPaging *)paging
                  success:(void (^)(NSArray <RemotePostTag *> *tags))success
                  failure:(nullable void (^)(NSError *error))failure;

/**
 Fetch a list of tags whose names or slugs match the provided search query. Case-insensitive.
 */
- (void)searchTagsWithName:(NSString *)nameQuery
                   success:(void (^)(NSArray <RemotePostTag *> *tags))success
                   failure:(nullable void (^)(NSError *error))failure;

@end

NS_ASSUME_NONNULL_END
