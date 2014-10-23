#import "MediaServiceRemoteXMLRPC.h"
#import "RemoteMedia.h"
#import "Blog.h"
#import <WordPressApi/WPXMLRPCClient.h>

@interface MediaServiceRemoteXMLRPC ()
@property (nonatomic) WPXMLRPCClient *api;
@end

@implementation MediaServiceRemoteXMLRPC

- (id)initWithApi:(WPXMLRPCClient *)api
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
    NSDictionary *data = @{
                           @"name": filename,
                           @"type": type,
                           @"bits": [NSInputStream inputStreamWithFileAtPath:path],
                           };
    NSArray *parameters = [blog getXMLRPCArgsWithExtra:data];
    NSURLRequest *request = [self.api requestWithMethod:@"wp.uploadFile" parameters:parameters];
    AFHTTPRequestOperation *operation = [self.api HTTPRequestOperationWithRequest:request
                                                                          success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                                              NSDictionary *response = (NSDictionary *)responseObject;

                                                                              if (![response isKindOfClass:[NSDictionary class]]) {
                                                                                  NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"The server returned an empty response. This usually means you need to increase the memory limit for your site.", @"")}];
                                                                                  if (failure) {
                                                                                      failure(error);
                                                                                  }
                                                                                  return;
                                                                              }

                                                                              NSNumber *ID = [response numberForKey:@"id"];
                                                                              NSString *url = [response stringForKey:@"url"];

                                                                              if (success) {
                                                                                  success(ID, url);
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
    NSArray *parameters = [blog getXMLRPCArgsWithExtra:mediaID];
    [self.api callMethod:@"wp.getMediaItem"
              parameters:parameters
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     if (success) {
                        NSDictionary * xmlRPCDictionary = (NSDictionary *)responseObject;
                        RemoteMedia * remoteMedia = [self remoteMediaFromXMLRPCDictionary:xmlRPCDictionary];
                        success(remoteMedia);
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
    NSDictionary *data = @{
                           @"name": media.file,
                           @"type": media.mimeType,
                           @"bits": [NSInputStream inputStreamWithFileAtPath:media.localURL],
                           };
    NSArray *parameters = [blog getXMLRPCArgsWithExtra:data];
    NSURLRequest *request = [self.api requestWithMethod:@"wp.uploadFile" parameters:parameters];
    AFHTTPRequestOperation *operation = [self.api HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (!success) {
            return;
        }
        NSDictionary *response = (NSDictionary *)responseObject;
        RemoteMedia * remoteMedia = [self remoteMediaFromUploadXMLRPCDictionary:response];
        success(remoteMedia);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
    
    [self.api.operationQueue addOperation:operation];
}

#pragma mark - Private methods

- (RemoteMedia *)remoteMediaFromXMLRPCDictionary:(NSDictionary*)json
{
    RemoteMedia * remoteMedia = [[RemoteMedia alloc] init];
    remoteMedia.url = [NSURL URLWithString:[json stringForKey:@"link"]];
    remoteMedia.title = [json stringForKey:@"title"];
    remoteMedia.width = [json numberForKeyPath:@"metadata.width"];
    remoteMedia.height = [json numberForKeyPath:@"metadata.height"];
    remoteMedia.mediaID = [json numberForKey:@"attachment_id"];
    remoteMedia.file = [[json objectForKeyPath:@"metadata.file"] lastPathComponent];
    remoteMedia.date = json[@"date_created_gmt"];
    remoteMedia.caption = [json stringForKey:@"caption"];
    remoteMedia.descriptionText = [json stringForKey:@"description"];
    remoteMedia.extension = [remoteMedia.file pathExtension];
    
    return remoteMedia;
}

- (RemoteMedia *)remoteMediaFromUploadXMLRPCDictionary:(NSDictionary*)json
{
    RemoteMedia * remoteMedia = [[RemoteMedia alloc] init];
    remoteMedia.url = [NSURL URLWithString:[json stringForKey:@"url"]];
    remoteMedia.mediaID = [json numberForKey:@"id"];
    remoteMedia.file = [[json objectForKeyPath:@"file"] lastPathComponent];
    remoteMedia.mimeType = [json stringForKey:@"type"];
    return remoteMedia;
}

@end
