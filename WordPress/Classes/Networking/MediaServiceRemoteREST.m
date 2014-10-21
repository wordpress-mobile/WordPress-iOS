#import "MediaServiceRemoteREST.h"
#import "WordPressComApi.h"
#import "Blog.h"
#import "RemoteMedia.h"
#import "NSDate+WordPressJSON.h"

@interface MediaServiceRemoteREST ()
@property (nonatomic) WordPressComApi *api;
@end

@implementation MediaServiceRemoteREST

- (id)initWithApi:(WordPressComApi *)api
{
    self = [super init];
    if (self) {
        _api = api;
    }
    return self;
}

- (AFHTTPRequestOperation *)operationToUploadFile:(NSString *)path
                                           ofType:(NSString *)type
                                     withFilename:(NSString *)filename
                                           toBlog:(Blog *)blog
                                          success:(void (^)(NSNumber *mediaID, NSString *url))success
                                          failure:(void (^)(NSError *))failure
{
    NSString *apiPath = [NSString stringWithFormat:@"sites/%@/media/new", blog.dotComID];
    NSMutableURLRequest *request = [self.api.requestSerializer multipartFormRequestWithMethod:@"POST" URLString:[[NSURL URLWithString:apiPath relativeToURL:self.api.baseURL] absoluteString] parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
        [formData appendPartWithFileURL:url name:@"media[]" fileName:filename mimeType:type error:nil];
    } error:nil];
    AFHTTPRequestOperation *operation = [self.api HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            NSDictionary *response = (NSDictionary *)responseObject;
            NSDictionary *media = [[response arrayForKey:@"media"] firstObject];
            NSNumber *mediaID = [media numberForKey:@"id"];
            NSString *url = [media stringForKey:@"link"];
            success(mediaID, url);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];

    return operation;
}

- (void) getMediaWithID:(NSNumber *) mediaID inBlog:(Blog *) blog
             withSuccess:(void (^)(RemoteMedia *remoteMedia))success
                 failure:(void (^)(NSError *error))failure {
    NSString *apiPath = [NSString stringWithFormat:@"sites/%@/media/%@", blog.dotComID, mediaID];
    NSDictionary * parameters = @{};
    
    [self.api GET:apiPath parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            NSDictionary *response = (NSDictionary *)responseObject;
            success([self remoteMediaFromJSONDictionary:response]);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (RemoteMedia *)remoteMediaFromJSONDictionary:(NSDictionary *)jsonMedia {
    RemoteMedia * remoteMedia=[[RemoteMedia alloc] init];
    remoteMedia.mediaID =  @([jsonMedia[@"ID"] intValue]);
    remoteMedia.url = [NSURL URLWithString:jsonMedia[@"URL"]];
    remoteMedia.guid = [NSURL URLWithString:jsonMedia[@"guid"]];
    remoteMedia.date = [NSDate dateWithWordPressComJSONString:jsonMedia[@"date"]];
    remoteMedia.postID = jsonMedia[@"post_ID"];
    remoteMedia.file = jsonMedia[@"file"];
    remoteMedia.mimeType = jsonMedia[@"mime_type"];
    remoteMedia.extension = jsonMedia[@"extension"];
    remoteMedia.title = jsonMedia[@"title"];
    remoteMedia.caption = jsonMedia[@"caption"];
    remoteMedia.descriptionText = jsonMedia[@"description"];
    remoteMedia.height = jsonMedia[@"height"];
    remoteMedia.width = jsonMedia[@"width"];
    remoteMedia.exif = jsonMedia[@"exif"];
    
    return remoteMedia;
}


@end
