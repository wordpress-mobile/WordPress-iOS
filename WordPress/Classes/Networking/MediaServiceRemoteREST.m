#import "MediaServiceRemoteREST.h"
#import "WordPressComApi.h"
#import "Blog.h"
#import "RemoteMedia.h"
#import "NSDate+WordPressJSON.h"

const NSInteger WPRestErrorCodeMediaNew = 10;

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
                                          success:(void (^)(RemoteMedia * remoteMedia))success
                                          failure:(void (^)(NSError *))failure
{
    NSString *apiPath = [NSString stringWithFormat:@"sites/%@/media/new", blog.dotComID];
    NSMutableURLRequest *request = [self.api.requestSerializer multipartFormRequestWithMethod:@"POST" URLString:[[NSURL URLWithString:apiPath relativeToURL:self.api.baseURL] absoluteString] parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
        [formData appendPartWithFileURL:url name:@"media[]" fileName:filename mimeType:type error:nil];
    } error:nil];
    AFHTTPRequestOperation *operation = [self.api HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *response = (NSDictionary *)responseObject;
        NSArray * errorList = response[@"error"];
        NSArray * mediaList = response[@"media"];
        if (mediaList.count > 0){
            RemoteMedia * remoteMedia = [self remoteMediaFromJSONDictionary:mediaList[0]];
            if (success){
                success(remoteMedia);
            }
        } else {
            DDLogDebug(@"Error uploading file: %@", errorList);
            NSError * error = nil;
            if (errorList.count > 0){
                NSDictionary * errorDictionary = @{NSLocalizedDescriptionKey: errorList[0]};
                error = [NSError errorWithDomain:WordPressRestApiErrorDomain code:WPRestErrorCodeMediaNew userInfo:errorDictionary];
            }
            if (failure){
                failure(error);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];

    return operation;
}

- (void)getMediaWithID:(NSNumber *)mediaID
               forBlog:(Blog *)blog
               success:(void (^)(RemoteMedia *remoteMedia))success
               failure:(void (^)(NSError *error))failure
{
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

- (void)createMedia:(RemoteMedia *)media
            forBlog:(Blog *)blog
            success:(void (^)(RemoteMedia *remoteMedia))success
            failure:(void (^)(NSError *error))failure
{
    NSOperation * operation = [self operationToUploadFile:media.localURL ofType:media.mimeType withFilename:media.file toBlog:blog success:success failure:failure];
    
    [self.api.operationQueue addOperation:operation];
}

- (RemoteMedia *)remoteMediaFromJSONDictionary:(NSDictionary *)jsonMedia
{
    RemoteMedia * remoteMedia=[[RemoteMedia alloc] init];    
    if (jsonMedia[@"id"]){
        remoteMedia.mediaID =  @([jsonMedia[@"id"] intValue]);
        remoteMedia.url = [NSURL URLWithString:jsonMedia[@"link"]];
        //remoteMedia.guid = [NSURL URLWithString:jsonMedia[@"guid"]];
        remoteMedia.date = [NSDate dateWithWordPressComJSONString:jsonMedia[@"date"]];
        remoteMedia.postID = jsonMedia[@"parent"];
        remoteMedia.file = jsonMedia[@"metadata"][@"file"];
        //remoteMedia.mimeType = jsonMedia[@"mime_type"];
        remoteMedia.extension = [jsonMedia[@"metadata"][@"file"] pathExtension];
        remoteMedia.title = jsonMedia[@"title"];
        remoteMedia.caption = jsonMedia[@"caption"];
        //remoteMedia.descriptionText = jsonMedia[@"description"];
        remoteMedia.height = jsonMedia[@"metadata"][@"height"];
        remoteMedia.width = jsonMedia[@"metadata"][@"width"];
        remoteMedia.exif = jsonMedia[@"metadata"][@"image_meta"];
    } else {
        // v1.1
        remoteMedia.mediaID =  jsonMedia[@"ID"];
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
    }
    return remoteMedia;
}


@end
