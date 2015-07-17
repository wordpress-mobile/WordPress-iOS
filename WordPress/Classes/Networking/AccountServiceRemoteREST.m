#import "AccountServiceRemoteREST.h"
#import "WordPressComApi.h"
#import "RemoteBlog.h"
#import "Constants.h"
#import "WPAccount.h"
#import "JetpackREST.h"

static NSString * const UserDictionaryIDKey = @"ID";
static NSString * const UserDictionaryUsernameKey = @"username";
static NSString * const UserDictionaryEmailKey = @"email";
static NSString * const UserDictionaryDisplaynameKey = @"display_name";
static NSString * const UserDictionaryPrimaryBlogKey = @"primary_blog";
static NSString * const UserDictionaryAvatarURLKey = @"avatar_URL";

@implementation AccountServiceRemoteREST

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

- (void)getDetailsForAccount:(WPAccount *)account
                     success:(void (^)(RemoteUser *remoteUser))success
                     failure:(void (^)(NSError *error))failure
{
    // IMPORTANT: We're adding this assertion even though the account is not used here to let the
    // caller know this parameter needs to be set (following the documentation of the protocol).
    // This parameter is used and required by the XMLRPC variant of this method.
    //
    NSParameterAssert([account isKindOfClass:[WPAccount class]]);
    
    NSString *path = @"me";
    [self.api GET:path
       parameters:nil
          success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
              if (!success) {
                  return;
              }
              RemoteUser *remoteUser = [self remoteUserFromDictionary:responseObject];
              success(remoteUser);
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              if (failure) {
                  failure(error);
              }
          }];
}

- (void)updateBlogsVisibility:(NSDictionary *)blogs
                      success:(void (^)())success
                      failure:(void (^)(NSError *))failure
{
    NSParameterAssert([blogs isKindOfClass:[NSDictionary class]]);
    NSMutableDictionary *sites = [NSMutableDictionary dictionaryWithCapacity:blogs.count];
    [blogs enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSParameterAssert([key isKindOfClass:[NSNumber class]]);
        NSParameterAssert([obj isKindOfClass:[NSNumber class]]);
        NSString *blogID = [key stringValue];
        sites[blogID] = obj;
    }];

    NSDictionary *parameters = @{
                                 @"sites": sites,
                                 };
    NSString *path = @"me/sites";
    [self.api POST:path
        parameters:parameters
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               if (success) {
                   success();
               }
           } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               if (failure) {
                   failure(error);
               }
           }];
}

#pragma mark - Private Methods

- (RemoteUser *)remoteUserFromDictionary:(NSDictionary *)dictionary
{
    RemoteUser *remoteUser = [RemoteUser new];
    remoteUser.userID = [dictionary numberForKey:UserDictionaryIDKey];
    remoteUser.username = [dictionary stringForKey:UserDictionaryUsernameKey];
    remoteUser.email = [dictionary stringForKey:UserDictionaryEmailKey];
    remoteUser.displayName = [dictionary stringForKey:UserDictionaryDisplaynameKey];
    remoteUser.primaryBlogID = [dictionary numberForKey:UserDictionaryPrimaryBlogKey];
    remoteUser.avatarURL = [dictionary stringForKey:UserDictionaryAvatarURLKey];
    return remoteUser;
}

- (NSArray *)remoteBlogsFromJSONArray:(NSArray *)jsonBlogs
{
    NSMutableArray *remoteBlogs = [NSMutableArray arrayWithCapacity:[jsonBlogs count]];
    for (NSDictionary *jsonBlog in jsonBlogs) {
        BOOL isJetpack = [jsonBlog[@"jetpack"] boolValue];
        if (!isJetpack || JetpackREST.enabled) {
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
    blog.desc = [jsonBlog stringForKey:@"description"];
    blog.url = [jsonBlog stringForKey:@"URL"];
    blog.xmlrpc = [jsonBlog stringForKeyPath:@"meta.links.xmlrpc"];
    blog.jetpack = [[jsonBlog numberForKey:@"jetpack"] boolValue];
    blog.icon = [jsonBlog stringForKeyPath:@"icon.img"];
    blog.visible = [[jsonBlog numberForKey:@"visible"] boolValue];
    return blog;
}

@end
