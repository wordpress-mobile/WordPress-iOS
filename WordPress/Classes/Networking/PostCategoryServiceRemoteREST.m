#import "PostCategoryServiceRemoteREST.h"
#import "WordPressComApi.h"
#import "Blog.h"
#import "RemotePostCategory.h"

@implementation PostCategoryServiceRemoteREST

- (void)getCategoriesForBlog:(Blog *)blog
                     success:(void (^)(NSArray *))success
                     failure:(void (^)(NSError *))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/categories?context=edit", blog.dotComID];
    NSString *requestUrl = [self requestUrlForDefaultApiVersionAndResourceUrl:path];
    
    [self.api GET:requestUrl
       parameters:nil
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              if (success) {
                  success([self remoteCategoriesWithJSONArray:responseObject[@"categories"]]);
              }
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              if (failure) {
                  failure(error);
              }
          }];
}

- (void)createCategory:(RemotePostCategory *)category
               forBlog:(Blog *)blog
               success:(void (^)(RemotePostCategory *))success
               failure:(void (^)(NSError *))failure
{
    NSParameterAssert(category.name.length > 0);
    NSString *path = [NSString stringWithFormat:@"sites/%@/categories/new?context=edit", blog.dotComID];
    NSString *requestUrl = [self requestUrlForDefaultApiVersionAndResourceUrl:path];
    
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

- (NSArray *)remoteCategoriesWithJSONArray:(NSArray *)jsonArray
{
    NSMutableArray *categories = [NSMutableArray arrayWithCapacity:jsonArray.count];
    for (NSDictionary *jsonCategory in jsonArray) {
        [categories addObject:[self remoteCategoryWithJSONDictionary:jsonCategory]];
    }
    return [NSArray arrayWithArray:categories];
}

- (RemotePostCategory *)remoteCategoryWithJSONDictionary:(NSDictionary *)jsonCategory
{
    RemotePostCategory *category = [RemotePostCategory new];
    category.categoryID = jsonCategory[@"ID"];
    category.name = jsonCategory[@"name"];
    category.parentID = jsonCategory[@"parent"];
    return category;
}

@end
