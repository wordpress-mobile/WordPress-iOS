#import "TaxonomyServiceRemoteREST.h"
#import "WordPressComApi.h"
#import "RemotePostCategory.h"
#import "RemotePostTag.h"

static NSString * const TaxonomyServiceRemoteRESTCategoryTypeIdentifier = @"categories";
static NSString * const TaxonomyServiceRemoteRESTTagTypeIdentifier = @"tags";

@implementation TaxonomyServiceRemoteREST

#pragma mark - categories

- (void)createCategory:(RemotePostCategory *)category
               success:(void (^)(RemotePostCategory *))success
               failure:(void (^)(NSError *))failure
{
    NSParameterAssert(category.name.length > 0);
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"name"] = category.name;
    if (category.parentID) {
        parameters[@"parent"] = category.parentID;
    }
    
    [self createTaxonomyWithType:TaxonomyServiceRemoteRESTCategoryTypeIdentifier
                      parameters:parameters
                         success:^(id responseObject) {
                             RemotePostCategory *receivedCategory = [self remoteCategoryWithJSONDictionary:responseObject];
                             if (success) {
                                 success(receivedCategory);
                             }
                         } failure:failure];
}

- (void)getCategoriesWithSuccess:(void (^)(NSArray <RemotePostCategory *> *))success
                         failure:(void (^)(NSError *))failure
{
    [self getTaxonomyWithType:TaxonomyServiceRemoteRESTCategoryTypeIdentifier
                   parameters:nil
                      success:^(id responseObject) {
                          if (success) {
                              success([self remoteCategoriesWithJSONArray:[responseObject arrayForKey:@"categories"]]);
                          }
                      } failure:failure];
}

#pragma mark - tags

- (void)getTagsWithSuccess:(void (^)(NSArray <RemotePostTag *> *tags))success
                   failure:(void (^)(NSError *error))failure
{
    [self getTaxonomyWithType:TaxonomyServiceRemoteRESTTagTypeIdentifier
                   parameters:nil
                      success:^(id responseObject) {
                          if (success) {
                              success([self remoteTagsWithJSONArray:[responseObject arrayForKey:@"tags"]]);
                          }
                      } failure:failure];
}

#pragma mark - default methods

- (void)createTaxonomyWithType:(NSString *)typeIdentifier
                    parameters:(NSDictionary *)parameters
                       success:(void (^)(id responseObject))success
                       failure:(void (^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/%@/new?context=edit", self.siteID, typeIdentifier];
    NSString *requestUrl = [self pathForEndpoint:path withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    [self.api POST:requestUrl
        parameters:parameters
           success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
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
                    success:(void (^)(id responseObject))success
                    failure:(void (^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/%@?context=edit", self.siteID, typeIdentifier];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    [self.api GET:requestUrl
       parameters:parameters
          success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
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
    RemotePostCategory *category = [RemotePostCategory new];
    category.categoryID = [jsonCategory numberForKey:@"ID"];
    category.name = [jsonCategory stringForKey:@"name"];
    category.parentID = [jsonCategory numberForKey:@"parent"];
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
    tag.tagID = [jsonTag numberForKey:@"ID"];
    tag.name = [jsonTag stringForKey:@"name"];
    tag.slug = [jsonTag stringForKey:@"slug"];
    return tag;
}

@end
