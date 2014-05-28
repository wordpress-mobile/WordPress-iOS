#import "AccountServiceRemoteXMLRPC.h"
#import <WordPressApi/WordPressXMLRPCApi.h>

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

#pragma mark - Private Methods

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
    blog.ID = xmlrpcBlog[@"blogid"];
    blog.title = xmlrpcBlog[@"blogName"];
    blog.url = xmlrpcBlog[@"url"];
    blog.xmlrpc = [self.api.xmlrpc absoluteString];
    return blog;
}

@end
