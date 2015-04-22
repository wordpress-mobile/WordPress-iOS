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
    // use simulated responseObject until API supports getting all posts statuses via "get_post_stati"
    success([self remoteStatusesFromXMLRPCDictionary:[self simulatedRemotePostStatusResponseObject]]);
}

- (NSDictionary *)simulatedRemotePostStatusResponseObject
{
    // simulated response object as if calling function "get_post_stati(null, 'objects')" within WordPress
    // response includes custom statuses that were auto-registered via the "Edit Flow" WordPress plugin
    NSString *responseString = @""
    "{\n    \"assigned\": {\n        \"protected\": true,\n        \"label\": \"Assigned\",\n        \"exclude_from_search\": false,\n        \"label_count\": {\n            \"0\": \"Assigned <span class='count'>(%s)</span>\",\n            \"1\": \"Assigned <span class='count'>(%s)</span>\",\n            \"domain\": \"\",\n            \"singular\": \"Assigned <span class='count'>(%s)</span>\",\n            \"plural\": \"Assigned <span class='count'>(%s)</span>\",\n            \"context\": \"\"\n        },\n        \"private\": false,\n        \"internal\": false,\n        \"public\": false,\n        \"_builtin\": false,\n        \"name\": \"assigned\",\n        \"show_in_admin_status_list\": true,\n        \"publicly_queryable\": false,\n        \"show_in_admin_all_list\": true\n    },\n    \"prompt\": {\n        \"protected\": true,\n        \"label\": \"Prompt\",\n        \"exclude_from_search\": false,\n        \"label_count\": {\n            \"0\": \"Prompt <span class='count'>(%s)</span>\",\n            \"1\": \"Prompt <span class='count'>(%s)</span>\",\n            \"domain\": \"\",\n            \"singular\": \"Prompt <span class='count'>(%s)</span>\",\n            \"plural\": \"Prompt <span class='count'>(%s)</span>\",\n            \"context\": \"\"\n        },\n        \"private\": false,\n        \"internal\": false,\n        \"public\": false,\n        \"_builtin\": false,\n        \"name\": \"prompt\",\n        \"show_in_admin_status_list\": true,\n        \"publicly_queryable\": false,\n        \"show_in_admin_all_list\": true\n    },\n    \"auto-draft\": {\n        \"protected\": false,\n        \"label\": \"auto-draft\",\n        \"exclude_from_search\": true,\n        \"label_count\": [\n            \"auto-draft\",\n            \"auto-draft\"\n        ],\n        \"private\": false,\n        \"internal\": true,\n        \"public\": false,\n        \"_builtin\": true,\n        \"name\": \"auto-draft\",\n        \"show_in_admin_status_list\": false,\n        \"publicly_queryable\": false,\n        \"show_in_admin_all_list\": false\n    },\n    \"publish\": {\n        \"protected\": false,\n        \"label\": \"Published\",\n        \"exclude_from_search\": false,\n        \"label_count\": {\n            \"0\": \"Published <span class=\\\"count\\\">(%s)</span>\",\n            \"1\": \"Published <span class=\\\"count\\\">(%s)</span>\",\n            \"domain\": \"\",\n            \"singular\": \"Published <span class=\\\"count\\\">(%s)</span>\",\n            \"plural\": \"Published <span class=\\\"count\\\">(%s)</span>\",\n            \"context\": \"\"\n        },\n        \"private\": false,\n        \"internal\": false,\n        \"public\": true,\n        \"_builtin\": true,\n        \"name\": \"publish\",\n        \"show_in_admin_status_list\": true,\n        \"publicly_queryable\": true,\n        \"show_in_admin_all_list\": true\n    },\n    \"trash\": {\n        \"protected\": false,\n        \"label\": \"Trash\",\n        \"exclude_from_search\": true,\n        \"label_count\": {\n            \"0\": \"Trash <span class=\\\"count\\\">(%s)</span>\",\n            \"1\": \"Trash <span class=\\\"count\\\">(%s)</span>\",\n            \"domain\": \"\",\n            \"singular\": \"Trash <span class=\\\"count\\\">(%s)</span>\",\n            \"plural\": \"Trash <span class=\\\"count\\\">(%s)</span>\",\n            \"context\": \"\"\n        },\n        \"private\": false,\n        \"internal\": true,\n        \"public\": false,\n        \"_builtin\": true,\n        \"name\": \"trash\",\n        \"show_in_admin_status_list\": true,\n        \"publicly_queryable\": false,\n        \"show_in_admin_all_list\": false\n    },\n    \"future\": {\n        \"protected\": true,\n        \"label\": \"Scheduled\",\n        \"exclude_from_search\": false,\n        \"label_count\": {\n            \"0\": \"Scheduled <span class=\\\"count\\\">(%s)</span>\",\n            \"1\": \"Scheduled <span class=\\\"count\\\">(%s)</span>\",\n            \"domain\": \"\",\n            \"singular\": \"Scheduled <span class=\\\"count\\\">(%s)</span>\",\n            \"plural\": \"Scheduled <span class=\\\"count\\\">(%s)</span>\",\n            \"context\": \"\"\n        },\n        \"private\": false,\n        \"internal\": false,\n        \"public\": false,\n        \"_builtin\": true,\n        \"name\": \"future\",\n        \"show_in_admin_status_list\": true,\n        \"publicly_queryable\": false,\n        \"show_in_admin_all_list\": true\n    },\n    \"in-progress\": {\n        \"protected\": true,\n        \"label\": \"In Progress\",\n        \"exclude_from_search\": false,\n        \"label_count\": {\n            \"0\": \"In Progress <span class='count'>(%s)</span>\",\n            \"1\": \"In Progress <span class='count'>(%s)</span>\",\n            \"domain\": \"\",\n            \"singular\": \"In Progress <span class='count'>(%s)</span>\",\n            \"plural\": \"In Progress <span class='count'>(%s)</span>\",\n            \"context\": \"\"\n        },\n        \"private\": false,\n        \"internal\": false,\n        \"public\": false,\n        \"_builtin\": false,\n        \"name\": \"in-progress\",\n        \"show_in_admin_status_list\": true,\n        \"publicly_queryable\": false,\n        \"show_in_admin_all_list\": true\n    },\n    \"pitch\": {\n        \"protected\": true,\n        \"label\": \"Pitch\",\n        \"exclude_from_search\": false,\n        \"label_count\": {\n            \"0\": \"Pitch <span class='count'>(%s)</span>\",\n            \"1\": \"Pitch <span class='count'>(%s)</span>\",\n            \"domain\": \"\",\n            \"singular\": \"Pitch <span class='count'>(%s)</span>\",\n            \"plural\": \"Pitch <span class='count'>(%s)</span>\",\n            \"context\": \"\"\n        },\n        \"private\": false,\n        \"internal\": false,\n        \"public\": false,\n        \"_builtin\": false,\n        \"name\": \"pitch\",\n        \"show_in_admin_status_list\": true,\n        \"publicly_queryable\": false,\n        \"show_in_admin_all_list\": true\n    },\n    \"private\": {\n        \"protected\": false,\n        \"label\": \"Private\",\n        \"exclude_from_search\": false,\n        \"label_count\": {\n            \"0\": \"Private <span class=\\\"count\\\">(%s)</span>\",\n            \"1\": \"Private <span class=\\\"count\\\">(%s)</span>\",\n            \"domain\": \"\",\n            \"singular\": \"Private <span class=\\\"count\\\">(%s)</span>\",\n            \"plural\": \"Private <span class=\\\"count\\\">(%s)</span>\",\n            \"context\": \"\"\n        },\n        \"private\": true,\n        \"internal\": false,\n        \"public\": false,\n        \"_builtin\": true,\n        \"name\": \"private\",\n        \"show_in_admin_status_list\": true,\n        \"publicly_queryable\": false,\n        \"show_in_admin_all_list\": true\n    },\n    \"inherit\": {\n        \"protected\": false,\n        \"label\": \"inherit\",\n        \"exclude_from_search\": false,\n        \"label_count\": [\n            \"inherit\",\n            \"inherit\"\n        ],\n        \"private\": false,\n        \"internal\": true,\n        \"public\": false,\n        \"_builtin\": true,\n        \"name\": \"inherit\",\n        \"show_in_admin_status_list\": false,\n        \"publicly_queryable\": false,\n        \"show_in_admin_all_list\": false\n    },\n    \"draft\": {\n        \"protected\": true,\n        \"label\": \"Draft\",\n        \"exclude_from_search\": false,\n        \"label_count\": {\n            \"0\": \"Draft <span class='count'>(%s)</span>\",\n            \"1\": \"Draft <span class='count'>(%s)</span>\",\n            \"domain\": \"\",\n            \"singular\": \"Draft <span class='count'>(%s)</span>\",\n            \"plural\": \"Draft <span class='count'>(%s)</span>\",\n            \"context\": \"\"\n        },\n        \"private\": false,\n        \"internal\": false,\n        \"public\": false,\n        \"_builtin\": false,\n        \"name\": \"draft\",\n        \"show_in_admin_status_list\": true,\n        \"publicly_queryable\": false,\n        \"show_in_admin_all_list\": true\n    },\n    \"pending\": {\n        \"protected\": true,\n        \"label\": \"Pending Review\",\n        \"exclude_from_search\": false,\n        \"label_count\": {\n            \"0\": \"Pending Review <span class='count'>(%s)</span>\",\n            \"1\": \"Pending Review <span class='count'>(%s)</span>\",\n            \"domain\": \"\",\n            \"singular\": \"Pending Review <span class='count'>(%s)</span>\",\n            \"plural\": \"Pending Review <span class='count'>(%s)</span>\",\n            \"context\": \"\"\n        },\n        \"private\": false,\n        \"internal\": false,\n        \"public\": false,\n        \"_builtin\": false,\n        \"name\": \"pending\",\n        \"show_in_admin_status_list\": true,\n        \"publicly_queryable\": false,\n        \"show_in_admin_all_list\": true\n    }\n}";
    
    NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:[responseString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    NSAssert([responseObject isKindOfClass:[NSDictionary class]], @"Response should be a dictionary.");
    
    return responseObject;
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
