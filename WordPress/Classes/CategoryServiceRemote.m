#import "CategoryServiceRemote.h"
#import "Blog.h"
#import "Blog+Jetpack.h"
#import "WordPressComApi.h"

@implementation CategoryServiceRemote {
    WordPressComApi *_restClient;
    NSNumber *_siteId;
}

- (id)initWithBlog:(Blog *)blog {
    self = [super init];
    if (self) {
        _restClient = blog.restApi;
        _siteId = blog.dotComID;
    }
    return self;
}

- (void)createCategoryWithName:(NSString *)name parentCategoryID:(NSNumber *)parentCategoryID success:(void (^)(NSNumber *))success failure:(void (^)(NSError *))failure {
    // http://developer.wordpress.com/docs/api/1/post/sites/%24site/categories/new/
    NSString *path = [NSString stringWithFormat:@"sites/%@/categories/new", _siteId];
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

@end
