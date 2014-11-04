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
                                          success:(void (^)(RemoteMedia * media))success
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
            
            RemoteMedia * remoteMedia = [self remoteMediaFromUploadXMLRPCDictionary:response];
            if (success){
                success(remoteMedia);
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
    NSOperation * operation = [self operationToUploadFile:media.localURL ofType:media.mimeType withFilename:media.file toBlog:blog success:success failure:failure];
    
    [self.api.operationQueue addOperation:operation];
}

#pragma mark - Private methods

- (RemoteMedia *)remoteMediaFromXMLRPCDictionary:(NSDictionary*)xmlRPC
{
    RemoteMedia * remoteMedia = [[RemoteMedia alloc] init];
    remoteMedia.url = [NSURL URLWithString:[xmlRPC stringForKey:@"link"]];
    remoteMedia.title = [xmlRPC stringForKey:@"title"];
    remoteMedia.width = [xmlRPC numberForKeyPath:@"metadata.width"];
    remoteMedia.height = [xmlRPC numberForKeyPath:@"metadata.height"];
    remoteMedia.mediaID = [xmlRPC numberForKey:@"attachment_id"];
    remoteMedia.file = [[xmlRPC objectForKeyPath:@"metadata.file"] lastPathComponent];
    remoteMedia.date = xmlRPC[@"date_created_gmt"];
    remoteMedia.caption = [xmlRPC stringForKey:@"caption"];
    remoteMedia.descriptionText = [xmlRPC stringForKey:@"description"];
    remoteMedia.extension = [remoteMedia.file pathExtension];
    
    return remoteMedia;
}

- (RemoteMedia *)remoteMediaFromUploadXMLRPCDictionary:(NSDictionary*)xmlRPC
{
    RemoteMedia * remoteMedia = [[RemoteMedia alloc] init];
    remoteMedia.url = [NSURL URLWithString:[xmlRPC stringForKey:@"url"]];
    remoteMedia.mediaID = [xmlRPC numberForKey:@"id"];
    remoteMedia.file = [[xmlRPC objectForKeyPath:@"file"] lastPathComponent];
    remoteMedia.mimeType = [xmlRPC stringForKey:@"type"];
    remoteMedia.extension = [[[xmlRPC objectForKeyPath:@"file"] lastPathComponent] pathExtension];
    return remoteMedia;
}

@end
