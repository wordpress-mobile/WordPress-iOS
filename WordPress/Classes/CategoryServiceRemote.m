#import "CategoryServiceRemote.h"
#import "Blog.h"
#import "Blog+Jetpack.h"
#import "WordPressComApi.h"

NSString *const CategoryServiceRemoteKeyID = @"id";
NSString *const CategoryServiceRemoteKeyName = @"name";
NSString *const CategoryServiceRemoteKeyParent = @"parent";

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
    // http://developer.wordpress.com/docs/api/1/get/sites/%24site/categories/
    NSString *path = [NSString stringWithFormat:@"sites/%@/categories", siteID];
    [_restClient getPath:path
              parameters:nil
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     if (success) {
                         NSDictionary *response = (NSDictionary *)responseObject;
                         if (![response isKindOfClass:[NSDictionary class]]) {
                             DDLogError(@"sites/$site/categories returned an unexpected object type for categories: %@", responseObject);
                             response = @{};
                         }
                         NSArray *receivedCategories = [response arrayForKey:@"categories"];
                         if (!receivedCategories) {
                             DDLogError(@"sites/$site/categories returned an unexpected format: %@", response);
                             receivedCategories = @[];
                         }
                         NSMutableArray *categories = [NSMutableArray arrayWithCapacity:[receivedCategories count]];
                         for (NSDictionary *receivedCategory in receivedCategories) {
                             if (![receivedCategory isKindOfClass:[NSDictionary class]]) {
                                 DDLogError(@"sites/$site/categories includes a category with an unexpected type: %@", receivedCategory);
                                 continue;
                             }
                             NSDictionary *category = @{
                                                        CategoryServiceRemoteKeyID: [receivedCategory numberForKey:@"ID"],
                                                        CategoryServiceRemoteKeyName: [receivedCategory stringForKey:@"name"],
                                                        CategoryServiceRemoteKeyParent: [receivedCategory numberForKey:@"parent"],
                                                        };
                             [categories addObject:category];
                         }

                         success([categories copy]);
                     }
                 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     if (failure) {
                         failure(error);
                     }
                 }];
}

@end
