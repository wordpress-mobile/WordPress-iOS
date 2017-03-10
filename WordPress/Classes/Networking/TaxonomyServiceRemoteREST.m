#import "TaxonomyServiceRemoteREST.h"
#import "WordPress-Swift.h"
#import "RemotePostCategory.h"
#import "RemotePostTag.h"
#import "RemoteTaxonomyPaging.h"

NS_ASSUME_NONNULL_BEGIN

static NSString * const TaxonomyRESTCategoryIdentifier = @"categories";
static NSString * const TaxonomyRESTTagIdentifier = @"tags";

static NSString * const TaxonomyRESTIDParameter = @"ID";
static NSString * const TaxonomyRESTNameParameter = @"name";
static NSString * const TaxonomyRESTSlugParameter = @"slug";
static NSString * const TaxonomyRESTParentParameter = @"parent";
static NSString * const TaxonomyRESTSearchParameter = @"search";
static NSString * const TaxonomyRESTOrderParameter = @"order";
static NSString * const TaxonomyRESTOrderByParameter = @"order_by";
static NSString * const TaxonomyRESTNumberParameter = @"number";
static NSString * const TaxonomyRESTOffsetParameter = @"offset";
static NSString * const TaxonomyRESTPageParameter = @"page";

static NSUInteger const TaxonomyRESTNumberMaxValue = 1000;

@implementation TaxonomyServiceRemoteREST

#pragma mark - categories

- (void)createCategory:(RemotePostCategory *)category
               success:(nullable void (^)(RemotePostCategory *))success
               failure:(nullable void (^)(NSError *))failure
{
    NSParameterAssert(category.name.length > 0);
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[TaxonomyRESTNameParameter] = category.name;
    if (category.parentID) {
        parameters[TaxonomyRESTParentParameter] = category.parentID;
    }
    
    [self createTaxonomyWithType:TaxonomyRESTCategoryIdentifier
                      parameters:parameters
                         success:^(NSDictionary *taxonomyDictionary) {
                             RemotePostCategory *receivedCategory = [self remoteCategoryWithJSONDictionary:taxonomyDictionary];
                             if (success) {
                                 success(receivedCategory);
                             }
                         } failure:failure];
}

- (void)getCategoriesWithSuccess:(void (^)(NSArray <RemotePostCategory *> *))success
                         failure:(nullable void (^)(NSError *))failure
{
    [self getTaxonomyWithType:TaxonomyRESTCategoryIdentifier
                   parameters:@{TaxonomyRESTNumberParameter: @(TaxonomyRESTNumberMaxValue)}
                      success:^(NSDictionary *responseObject) {
                          success([self remoteCategoriesWithJSONArray:[responseObject arrayForKey:TaxonomyRESTCategoryIdentifier]]);
                      } failure:failure];
}

- (void)getCategoriesWithPaging:(RemoteTaxonomyPaging *)paging
                        success:(void (^)(NSArray <RemotePostCategory *> *categories))success
                        failure:(nullable void (^)(NSError *error))failure
{
    [self getTaxonomyWithType:TaxonomyRESTCategoryIdentifier
                   parameters:[self parametersForPaging:paging]
                      success:^(NSDictionary *responseObject) {
                          success([self remoteCategoriesWithJSONArray:[responseObject arrayForKey:TaxonomyRESTCategoryIdentifier]]);
                      } failure:failure];
}

- (void)searchCategoriesWithName:(NSString *)nameQuery
                         success:(void (^)(NSArray <RemotePostCategory *> *tags))success
                         failure:(nullable void (^)(NSError *error))failure
{
    NSParameterAssert(nameQuery.length > 0);
    [self getTaxonomyWithType:TaxonomyRESTCategoryIdentifier
                   parameters:@{TaxonomyRESTSearchParameter: nameQuery}
                      success:^(NSDictionary *responseObject) {
                          success([self remoteCategoriesWithJSONArray:[responseObject arrayForKey:TaxonomyRESTCategoryIdentifier]]);
                      } failure:failure];
}

#pragma mark - tags

- (void)createTag:(RemotePostTag *)tag
          success:(nullable void (^)(RemotePostTag *tag))success
          failure:(nullable void (^)(NSError *error))failure
{
    NSParameterAssert(tag.name.length > 0);
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[TaxonomyRESTNameParameter] = tag.name;
    
    [self createTaxonomyWithType:TaxonomyRESTTagIdentifier
                      parameters:parameters
                         success:^(NSDictionary *taxonomyDictionary) {
                             RemotePostTag *receivedTag = [self remoteTagWithJSONDictionary:taxonomyDictionary];
                             if (success) {
                                 success(receivedTag);
                             }
                         } failure:failure];
}

- (void)getTagsWithSuccess:(void (^)(NSArray <RemotePostTag *> *tags))success
                   failure:(nullable void (^)(NSError *error))failure
{
    [self getTaxonomyWithType:TaxonomyRESTTagIdentifier
                   parameters:nil
                      success:^(NSDictionary *responseObject) {
                          success([self remoteTagsWithJSONArray:[responseObject arrayForKey:TaxonomyRESTTagIdentifier]]);
                      } failure:failure];
}

- (void)getTagsWithPaging:(RemoteTaxonomyPaging *)paging
                  success:(void (^)(NSArray <RemotePostTag *> *tags))success
                  failure:(nullable void (^)(NSError *error))failure
{
    [self getTaxonomyWithType:TaxonomyRESTTagIdentifier
                   parameters:[self parametersForPaging:paging]
                      success:^(NSDictionary *responseObject) {
                          success([self remoteTagsWithJSONArray:[responseObject arrayForKey:TaxonomyRESTTagIdentifier]]);
                      } failure:failure];
}

- (void)searchTagsWithName:(NSString *)nameQuery
                   success:(void (^)(NSArray <RemotePostTag *> *tags))success
                   failure:(nullable void (^)(NSError *error))failure
{
    NSParameterAssert(nameQuery.length > 0);
    [self getTaxonomyWithType:TaxonomyRESTTagIdentifier
                   parameters:@{TaxonomyRESTSearchParameter: nameQuery}
                      success:^(NSDictionary *responseObject) {
                          success([self remoteTagsWithJSONArray:[responseObject arrayForKey:TaxonomyRESTTagIdentifier]]);
                      } failure:failure];
}

#pragma mark - default methods

- (void)createTaxonomyWithType:(NSString *)typeIdentifier
                    parameters:(nullable NSDictionary *)parameters
                       success:(void (^)(NSDictionary *taxonomyDictionary))success
                       failure:(nullable void (^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/%@/new?context=edit", self.siteID, typeIdentifier];
    NSString *requestUrl = [self pathForEndpoint:path withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];
    
    [self.wordPressComRestApi POST:requestUrl
        parameters:parameters
           success:^(id  _Nonnull responseObject, NSHTTPURLResponse *httpResponse) {
               if (![responseObject isKindOfClass:[NSDictionary class]]) {
                   NSString *message = [NSString stringWithFormat:@"Invalid response creating taxonomy of type: %@", typeIdentifier];
                   [self handleResponseErrorWithMessage:message url:requestUrl failure:failure];
                   return;
               }
               success(responseObject);
           } failure:^(NSError * _Nonnull error, NSHTTPURLResponse *httpResponse) {
               if (failure) {
                   failure(error);
               }
           }];
}

- (void)getTaxonomyWithType:(NSString *)typeIdentifier
                 parameters:(nullable NSDictionary *)parameters
                    success:(void (^)(NSDictionary *responseObject))success
                    failure:(nullable void (^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/%@?context=edit", self.siteID, typeIdentifier];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];
    
    [self.wordPressComRestApi GET:requestUrl
       parameters:parameters
          success:^(id  _Nonnull responseObject, NSHTTPURLResponse *httpResponse) {
              if (![responseObject isKindOfClass:[NSDictionary class]]) {
                  NSString *message = [NSString stringWithFormat:@"Invalid response requesting taxonomy of type: %@", typeIdentifier];
                  [self handleResponseErrorWithMessage:message url:requestUrl failure:failure];
                  return;
              }
              success(responseObject);
          } failure:^(NSError * _Nonnull error, NSHTTPURLResponse *httpResponse) {
              if (failure) {
                  failure(error);
              }
          }];
}

#pragma mark - helpers

- (NSArray <RemotePostCategory *> *)remoteCategoriesWithJSONArray:(NSArray *)jsonArray
{
    return [jsonArray wp_map:^id(NSDictionary *jsonCategory) {
        return [self remoteCategoryWithJSONDictionary:jsonCategory];
    }];
}

- (RemotePostCategory *)remoteCategoryWithJSONDictionary:(NSDictionary *)jsonCategory
{
    RemotePostCategory *category = [RemotePostCategory new];
    category.categoryID = [jsonCategory numberForKey:TaxonomyRESTIDParameter];
    category.name = [jsonCategory stringForKey:TaxonomyRESTNameParameter];
    category.parentID = [jsonCategory numberForKey:TaxonomyRESTParentParameter];
    return category;
}

- (NSArray <RemotePostTag *> *)remoteTagsWithJSONArray:(NSArray *)jsonArray
{
    return [jsonArray wp_map:^id(NSDictionary *jsonTag) {
        return [self remoteTagWithJSONDictionary:jsonTag];
    }];
}

- (RemotePostTag *)remoteTagWithJSONDictionary:(NSDictionary *)jsonTag
{
    RemotePostTag *tag = [RemotePostTag new];
    tag.tagID = [jsonTag numberForKey:TaxonomyRESTIDParameter];
    tag.name = [jsonTag stringForKey:TaxonomyRESTNameParameter];
    tag.slug = [jsonTag stringForKey:TaxonomyRESTSlugParameter];
    return tag;
}

- (NSDictionary *)parametersForPaging:(RemoteTaxonomyPaging *)paging
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    if (paging.number) {
        [dictionary setObject:paging.number forKey:TaxonomyRESTNumberParameter];
    }
    if (paging.offset) {
        [dictionary setObject:paging.offset forKey:TaxonomyRESTOffsetParameter];
    }
    if (paging.page) {
        [dictionary setObject:paging.page forKey:TaxonomyRESTPageParameter];
    }
    if (paging.order == RemoteTaxonomyPagingOrderAscending) {
        [dictionary setObject:@"ASC" forKey:TaxonomyRESTOrderParameter];
    } else if (paging.order == RemoteTaxonomyPagingOrderDescending) {
        [dictionary setObject:@"DESC" forKey:TaxonomyRESTOrderParameter];
    }
    if (paging.orderBy == RemoteTaxonomyPagingResultsOrderingByName) {
        [dictionary setObject:@"name" forKey:TaxonomyRESTOrderByParameter];
    } else if (paging.orderBy == RemoteTaxonomyPagingResultsOrderingByCount) {
        [dictionary setObject:@"count" forKey:TaxonomyRESTOrderByParameter];
    }
    return dictionary.count ? dictionary : nil;
}

- (void)handleResponseErrorWithMessage:(NSString *)message
                                   url:(NSString *)urlStr
                               failure:(nullable void(^)(NSError *error))failure
{
    DDLogError(@"%@ - URL: %@", message, urlStr);
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                         code:NSURLErrorBadServerResponse
                                     userInfo:@{NSLocalizedDescriptionKey: message}];
    if (failure) {
        failure(error);
    }
}

@end

NS_ASSUME_NONNULL_END
