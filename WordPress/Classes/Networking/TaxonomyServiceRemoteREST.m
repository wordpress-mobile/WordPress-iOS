#import "TaxonomyServiceRemoteREST.h"
#import "WordPressComApi.h"
#import "RemotePostCategory.h"
#import "RemotePostTag.h"

@implementation TaxonomyServiceRemoteREST

#pragma mark - categories

- (void)getCategoriesWithSuccess:(void (^)(NSArray <RemotePostCategory *> *))success
                         failure:(void (^)(NSError *))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/categories?context=edit", self.siteID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    [self.api GET:requestUrl
       parameters:nil
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              if (success) {
                  success([self remoteCategoriesWithJSONArray:[responseObject arrayForKey:@"categories"]]);
              }
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              if (failure) {
                  failure(error);
              }
          }];
}

- (void)createCategory:(RemotePostCategory *)category
               success:(void (^)(RemotePostCategory *))success
               failure:(void (^)(NSError *))failure
{
    NSParameterAssert(category.name.length > 0);
    NSString *path = [NSString stringWithFormat:@"sites/%@/categories/new?context=edit", self.siteID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"name"] = category.name;
    if (category.parentID) {
        parameters[@"parent"] = category.parentID;
    }

    [self.api POST:requestUrl
        parameters:parameters
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               RemotePostCategory *receivedCategory = [self remoteCategoryWithJSONDictionary:responseObject];
               if (success) {
                   success(receivedCategory);
               }
           } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               if (failure) {
                   failure(error);
               }
           }];
}

#pragma mark - tags

- (void)getTagsWithSuccess:(void (^)(NSArray <RemotePostTag *> *tags))success
                   failure:(void (^)(NSError *error))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/tags?context=edit", self.siteID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    [self.api GET:requestUrl
       parameters:nil
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              if (success) {
                  success([self remoteTagsWithJSONArray:[responseObject arrayForKey:@"tags"]]);
              }
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
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
