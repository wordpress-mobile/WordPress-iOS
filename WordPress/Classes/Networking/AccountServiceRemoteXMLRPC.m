#import "AccountServiceRemoteXMLRPC.h"
#import <WordPressApi.h>
#import "RemoteBlog.h"
#import "WPAccount.h"
#import "BLog.h"

static NSString * const UserDictionaryIDKey = @"user_id";
static NSString * const UserDictionaryUsernameKey = @"username";
static NSString * const UserDictionaryEmailKey = @"email";
static NSString * const UserDictionaryDisplaynameKey = @"display_name";

@interface AccountServiceRemoteXMLRPC ()
@property (nonatomic, strong) WordPressXMLRPCApi *api;
@end

@implementation AccountServiceRemoteXMLRPC

- (id)initWithApi:(WordPressXMLRPCApi *)api
{
    self = [super init];
    if (self) {
        _api = api;
    }

    return self;
}

- (void)getBlogsWithSuccess:(void (^)(NSArray *blogs))success failure:(void (^)(NSError *error))failure
{
    [self.api getBlogsWithSuccess:^(NSArray *blogs) {
        if (success) {
            success([self remoteBlogsFromXMLRPCArray:blogs]);
        }
    } failure:failure];
}

- (void)getDetailsForAccount:(WPAccount *)account success:(void (^)(RemoteUser *remoteUser))success failure:(void (^)(NSError *error))failure
{
    WPXMLRPCClient *client = [WPXMLRPCClient clientWithXMLRPCEndpoint:[NSURL URLWithString:account.xmlrpc]];
    Blog *blog = [account.blogs anyObject]; // All an account's blogs use the same XMLRPC endpoint and the same account info. Doesn't matter which blog we use for params.
    NSArray *parameters = [blog getXMLRPCArgsWithExtra:nil];
    [client callMethod:@"wp.getProfile"
            parameters:parameters
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   if (!success) {
                       return;
                   }
                   NSDictionary *response = (NSDictionary *)responseObject;
                   RemoteUser *remoteUser = [self remoteUserFromDictionary:response];
                   success(remoteUser);
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
    return remoteUser;
}

- (NSArray *)remoteBlogsFromXMLRPCArray:(NSArray *)xmlrpcBlogs
{
    NSMutableArray *remoteBlogs = [NSMutableArray arrayWithCapacity:[xmlrpcBlogs count]];
    for (NSDictionary *xmlrpcBlog in xmlrpcBlogs) {
        [remoteBlogs addObject:[self remoteBlogFromXMLRPCDictionary:xmlrpcBlog]];
    }
    return [NSArray arrayWithArray:remoteBlogs];
}

- (RemoteBlog *)remoteBlogFromXMLRPCDictionary:(NSDictionary *)xmlrpcBlog
{
    RemoteBlog *blog = [RemoteBlog new];
    blog.ID = [xmlrpcBlog numberForKey:@"blogid"];
    blog.title = [xmlrpcBlog stringForKey:@"blogName"];
    blog.url = [xmlrpcBlog stringForKey:@"url"];
    blog.xmlrpc = [self.api.xmlrpc absoluteString];
    return blog;
}

@end
