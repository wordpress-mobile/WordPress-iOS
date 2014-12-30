#import "AccountServiceRemoteREST.h"
#import "WordPressComApi.h"
#import "RemoteBlog.h"
#import "Constants.h"

@interface AccountServiceRemoteREST ()
@property (nonatomic, strong) WordPressComApi *api;
@end

@implementation AccountServiceRemoteREST

- (id)initWithApi:(WordPressComApi *)api
{
        self = [super init];
        if (self) {
            _api = api;
        }

        return self;
}

- (void)getBlogsWithSuccess:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure
{
    [self.api GET:@"me/sites"
       parameters:nil
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              if (success) {
                  success([self remoteBlogsFromJSONArray:responseObject[@"sites"]]);
              }
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              if (failure) {
                  failure(error);
              }
          }];
}

- (void)getDetailsWithSuccess:(void (^)(NSDictionary *userDetails))success failure:(void (^)(NSError *error))failure
{
    NSString *path = @"me";
    [self.api GET:path
       parameters:nil
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              if (success) {
                  NSString *email = responseObject[@"email"];
                  NSNumber *primaryBlogId = responseObject[@"primary_blog"];
                  NSMutableDictionary *userDetails = [NSMutableDictionary new];
                  if (email) {
                      userDetails[@"email"] = email;
                  }
                  if (primaryBlogId) {
                      userDetails[@"primary_blog"] = primaryBlogId;
                  }
                  success(userDetails);
              }
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              if (failure) {
                  failure(error);
              }
          }];
}

#pragma mark - Private Methods

- (NSArray *)remoteBlogsFromJSONArray:(NSArray *)jsonBlogs
{
    NSMutableArray *remoteBlogs = [NSMutableArray arrayWithCapacity:[jsonBlogs count]];
    for (NSDictionary *jsonBlog in jsonBlogs) {
        BOOL isJetpack = [jsonBlog[@"jetpack"] boolValue];
        if (!isJetpack || WPJetpackRESTEnabled) {
            [remoteBlogs addObject:[self remoteBlogFromJSONDictionary:jsonBlog]];
        }
    }
    return [NSArray arrayWithArray:remoteBlogs];
}

- (RemoteBlog *)remoteBlogFromJSONDictionary:(NSDictionary *)jsonBlog
{
    RemoteBlog *blog = [RemoteBlog new];
    blog.ID =  [jsonBlog numberForKey:@"ID"];
    blog.title = [jsonBlog stringForKey:@"name"];
    blog.url = [jsonBlog stringForKey:@"URL"];
    blog.xmlrpc = [jsonBlog stringForKeyPath:@"meta.links.xmlrpc"];
    return blog;
}

@end
