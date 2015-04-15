#import "PostStatusServiceRemoteXMLRPC.h"
#import "Blog.h"
#import "RemotePostStatus.h"
#import <NSString+Util.h>

@interface PostStatusServiceRemoteXMLRPC ()

@property (nonatomic, strong) WPXMLRPCClient *api;

@end

@implementation PostStatusServiceRemoteXMLRPC

- (instancetype)initWithApi:(WPXMLRPCClient *)api
{
    self = [super init];
    if (self) {
        _api = api;
    }
    
    return self;
}

- (void)getStatusesForBlog:(Blog *)blog success:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure
{
    NSArray *parameters = [blog getXMLRPCArgsWithExtra:nil];
    [self.api callMethod:@"wp.getPostStati"
              parameters:parameters
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     NSAssert([responseObject isKindOfClass:[NSDictionary class]], @"Response should be a dictionary.");
                     if (success) {
                         success([self remoteStatusesFromXMLRPCDictionary:responseObject]);
                     }
                 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     if (failure) failure(error);
                 }];
}

- (NSArray *)remoteStatusesFromXMLRPCDictionary:(NSDictionary *)xmlrpcDictionary
{
    NSArray *xmlrpcArray = [xmlrpcDictionary allValues];
    NSMutableArray *statuses = [NSMutableArray arrayWithCapacity:xmlrpcArray.count];
    for (NSDictionary *xmlrpcStatus in xmlrpcArray) {
        [statuses addObject:[self remoteStatusFromXMLRPCDictionary:xmlrpcStatus]];
    }
    return [NSArray arrayWithArray:statuses];
}

- (RemotePostStatus *)remoteStatusFromXMLRPCDictionary:(NSDictionary *)xmlrpcDictionary
{
    RemotePostStatus *postStatus = [RemotePostStatus new];
    postStatus.name = [xmlrpcDictionary stringForKey:@"name"];
    postStatus.label = [xmlrpcDictionary stringForKey:@"label"];
    postStatus.isProtected = [xmlrpcDictionary numberForKey:@"protected"];
    postStatus.isPrivate = [xmlrpcDictionary numberForKey:@"private"];
    postStatus.isPublic = [xmlrpcDictionary numberForKey:@"public"];
    return postStatus;
}

@end
