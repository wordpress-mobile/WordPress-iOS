#import "CategoryServiceRemote.h"
#import "Blog.h"
#import "Blog+Jetpack.h"
#import "WordPressComApi.h"

@implementation CategoryServiceRemote {
    WordPressComApi *_restClient;
}

- (id)initWithApi:(WordPressComApi *)api {
    self = [super init];
    if (self) {
        _restClient = api;
    }
    return self;
}

#pragma mark - CategoryServiceRemoteAPI

- (void)createCategoryWithName:(NSString *)name parentCategoryID:(NSNumber *)parentCategoryID siteID:(NSNumber *)siteID success:(void (^)(NSNumber *))success failure:(void (^)(NSError *))failure {
    // http://developer.wordpress.com/docs/api/1/post/sites/%24site/categories/new/
    NSString *path = [NSString stringWithFormat:@"sites/%@/categories/new", siteID];
    NSDictionary *parameters = @{
                                 @"name": name,
                                 @"parent": parentCategoryID,
                                 };
    [_restClient postPath:path
               parameters:parameters
                  success:^(AFHTTPRequestOperation *operation, id responseObject) {
                      NSNumber *categoryID = [responseObject numberForKey:@"ID"];
                      if (success) {
                          success(categoryID);
                      }
                  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                      if (failure) {
                          failure(error);
                      }
                  }];
}

- (void)getCategoriesForSiteWithID:(NSNumber *)siteID success:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure {
    // http://developer.wordpress.com/docs/api/1/post/sites/%24site/categories/
#warning Categories endpoint doesn't exist yet. Make sure to standardize response format
    NSString *path = [NSString stringWithFormat:@"sites/%@/categories/new", siteID];
    [_restClient getPath:path
              parameters:nil
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     if (success) {
                         success(responseObject);
                     }
                 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     if (failure) {
                         failure(error);
                     }
                 }];
}

@end
