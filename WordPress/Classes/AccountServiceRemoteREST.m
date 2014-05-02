#import "AccountServiceRemoteREST.h"
#import "WordPressComApi.h"

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
    [self.api getPath:@"me/sites"
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

#pragma mark - Private Methods

- (NSArray *)remoteBlogsFromJSONArray:(NSArray *)jsonBlogs
{
    NSMutableArray *remoteBlogs = [NSMutableArray arrayWithCapacity:[jsonBlogs count]];
    for (NSDictionary *jsonBlog in jsonBlogs) {
        BOOL isJetpack = [jsonBlog[@"jetpack"] boolValue];
        if (!isJetpack) {
            [remoteBlogs addObject:[self remoteBlogFromJSONDictionary:jsonBlog]];
        }
    }
    return [NSArray arrayWithArray:remoteBlogs];
}

- (RemoteBlog *)remoteBlogFromJSONDictionary:(NSDictionary *)jsonBlog
{
    RemoteBlog *blog = [RemoteBlog new];
    blog.ID = jsonBlog[@"ID"];
    blog.title = jsonBlog[@"name"];
    blog.url = jsonBlog[@"URL"];
    blog.xmlrpc = jsonBlog[@"meta"][@"links"][@"xmlrpc"];
    return blog;
}

@end
