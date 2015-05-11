#import "PostStatusServiceRemoteREST.h"
#import "WordPressComApi.h"
#import "Blog.h"
#import "RemotePostStatus.h"
#import "PostStatusServiceRemoteXMLRPC.h"

@interface PostStatusServiceRemoteREST ()

@property (nonatomic, strong) WordPressComApi *api;

@end

@implementation PostStatusServiceRemoteREST

- (instancetype)initWithApi:(WordPressComApi *)api
{
    self = [super init];
    if (self) {
        _api = api;
    }
    return self;
}

- (void)getStatusesForBlog:(Blog *)blog success:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure
{
    // use simulated responseObject until API supports getting all posts statuses via "get_post_stati"
    success([self remoteStatusesWithJSONDictionary:[self simulatedRemotePostStatusResponseObject]]);
}

- (NSDictionary *)simulatedRemotePostStatusResponseObject
{
    // using simulated response object from the XML-RPC implementation
    // unsure what the JSON API response format would look like
    PostStatusServiceRemoteXMLRPC *remote = [[PostStatusServiceRemoteXMLRPC alloc] init];
    return [remote simulatedRemotePostStatusResponseObject];
}

- (NSArray *)remoteStatusesWithJSONDictionary:(NSDictionary *)jsonDictionary
{    
    NSArray *jsonArray = [jsonDictionary allValues];
    NSMutableArray *statuses = [NSMutableArray arrayWithCapacity:jsonArray.count];
    for (NSDictionary *jsonStatus in jsonArray) {
        [statuses addObject:[self remoteStatusWithJSONDictionary:jsonStatus]];
    }
    return [NSArray arrayWithArray:statuses];
}

- (RemotePostStatus *)remoteStatusWithJSONDictionary:(NSDictionary *)jsonDictionary
{
    RemotePostStatus *postStatus = [RemotePostStatus new];
    postStatus.name = [jsonDictionary stringForKey:@"name"];
    postStatus.label = [jsonDictionary stringForKey:@"label"];
    postStatus.isProtected = [jsonDictionary numberForKey:@"protected"];
    postStatus.isPrivate = [jsonDictionary numberForKey:@"private"];
    postStatus.isPublic = [jsonDictionary numberForKey:@"public"];
    return postStatus;
}

@end
