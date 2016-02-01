#import "TaxonomyServiceRemoteREST.h"
#import "WordPressComApi.h"
#import "RemotePostCategory.h"
#import "RemotePostTag.h"
#import "RemoteTaxonomyPaging.h"

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

@implementation TaxonomyServiceRemoteREST

#pragma mark - categories

- (void)createCategory:(RemotePostCategory *)category
               success:(void (^)(RemotePostCategory *))success
               failure:(void (^)(NSError *))failure
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
                         failure:(void (^)(NSError *))failure
{
    [self getCategoriesWithPaging:nil
                          success:success
                          failure:failure];
}

- (void)getCategoriesWithPaging:(RemoteTaxonomyPaging *)paging
                        success:(void (^)(NSArray <RemotePostCategory *> *categories))success
                        failure:(void (^)(NSError *error))failure
{
    [self getTaxonomyWithType:TaxonomyRESTCategoryIdentifier
                   parameters:[self parametersForPaging:paging]
                      success:^(NSDictionary *responseObject) {
                          if (success) {
                              success([self remoteCategoriesWithJSONArray:[responseObject arrayForKey:TaxonomyRESTCategoryIdentifier]]);
                          }
                      } failure:failure];
}

- (void)searchCategoriesWithName:(NSString *)nameQuery
                   success:(void (^)(NSArray <RemotePostCategory *> *tags))success
                   failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(nameQuery.length > 0);
    [self getTaxonomyWithType:TaxonomyRESTCategoryIdentifier
                   parameters:@{TaxonomyRESTSearchParameter: nameQuery}
                      success:^(NSDictionary *responseObject) {
                          if (success) {
                              success([self remoteCategoriesWithJSONArray:[responseObject arrayForKey:TaxonomyRESTCategoryIdentifier]]);
                          }
                      } failure:failure];
}

#pragma mark - tags

- (void)getTagsWithSuccess:(void (^)(NSArray <RemotePostTag *> *tags))success
                   failure:(void (^)(NSError *error))failure
{
    [self getTagsWithPaging:nil
                    success:success
                    failure:failure];
}

- (void)getTagsWithPaging:(RemoteTaxonomyPaging *)paging
                  success:(void (^)(NSArray <RemotePostTag *> *tags))success
                  failure:(void (^)(NSError *error))failure
{
    [self getTaxonomyWithType:TaxonomyRESTTagIdentifier
                   parameters:[self parametersForPaging:paging]
                      success:^(NSDictionary *responseObject) {
                          if (success) {
                              success([self remoteTagsWithJSONArray:[responseObject arrayForKey:TaxonomyRESTTagIdentifier]]);
                          }
                      } failure:failure];
}

- (void)searchTagsWithName:(NSString *)nameQuery
                   success:(void (^)(NSArray <RemotePostTag *> *tags))success
                   failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(nameQuery.length > 0);
    [self getTaxonomyWithType:TaxonomyRESTTagIdentifier
                   parameters:@{TaxonomyRESTSearchParameter: nameQuery}
                      success:^(NSDictionary *responseObject) {
                          if (success) {
                              success([self remoteTagsWithJSONArray:[responseObject arrayForKey:TaxonomyRESTTagIdentifier]]);
                          }
                      } failure:failure];
}

#pragma mark - default methods

- (void)createTaxonomyWithType:(NSString *)typeIdentifier
                    parameters:(NSDictionary *)parameters
                       success:(void (^)(NSDictionary *taxonomyDictionary))success
                       failure:(void (^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/%@/new?context=edit", self.siteID, typeIdentifier];
    NSString *requestUrl = [self pathForEndpoint:path withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    [self.api POST:requestUrl
        parameters:parameters
           success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
               NSAssert([responseObject isKindOfClass:[NSDictionary class]], @"responseObject should be a dictionary");
               if (![responseObject isKindOfClass:[NSDictionary class]]) {
                   responseObject = nil;
               }
               if (success) {
                   success(responseObject);
               }
           } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
               if (failure) {
                   failure(error);
               }
           }];
}

- (void)getTaxonomyWithType:(NSString *)typeIdentifier
                 parameters:(id)parameters
                    success:(void (^)(NSDictionary *responseObject))success
                    failure:(void (^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/%@?context=edit", self.siteID, typeIdentifier];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    [self.api GET:requestUrl
       parameters:parameters
          success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
              NSAssert([responseObject isKindOfClass:[NSDictionary class]], @"responseObject should be a dictionary");
              if (![responseObject isKindOfClass:[NSDictionary class]]) {
                  responseObject = nil;
              }
              if (success) {
                  success(responseObject);
              }
          } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
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
    if (!jsonCategory) {
        return nil;
    }
    
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
    if (!jsonTag) {
        return nil;
    }
    
    RemotePostTag *tag = [RemotePostTag new];
    tag.tagID = [jsonTag numberForKey:TaxonomyRESTIDParameter];
    tag.name = [jsonTag stringForKey:TaxonomyRESTNameParameter];
    tag.slug = [jsonTag stringForKey:TaxonomyRESTSlugParameter];
    return tag;
}

- (NSDictionary *)parametersForPaging:(RemoteTaxonomyPaging *)paging
{
    if (!paging) {
        return nil;
    }
    
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

@end
