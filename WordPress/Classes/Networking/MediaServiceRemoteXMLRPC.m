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
           progress:(NSProgress **)progress
            success:(void (^)(RemoteMedia *remoteMedia))success
            failure:(void (^)(NSError *error))failure
{
    NSProgress *localProgress = [NSProgress progressWithTotalUnitCount:2];
    //The enconding of the request uses a NSData that has a progress
    [localProgress becomeCurrentWithPendingUnitCount:1];
    NSString *path = media.localURL;
    NSString *type = media.mimeType;
    NSString *filename = media.file;
    
    NSDictionary *data = @{
                           @"name": filename,
                           @"type": type,
                           @"bits": [NSInputStream inputStreamWithFileAtPath:path],
                           };
    NSArray *parameters = [blog getXMLRPCArgsWithExtra:data];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *directory = [paths objectAtIndex:0];
    NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *streamingCacheFilePath = [directory stringByAppendingPathComponent:guid];
    
    NSURLRequest *request = [self.api streamingRequestWithMethod:@"wp.uploadFile" parameters:parameters usingFilePathForCache:streamingCacheFilePath];
    [localProgress resignCurrent];
    
    AFHTTPRequestOperation *operation = [self.api HTTPRequestOperationWithRequest:request
      success:^(AFHTTPRequestOperation *operation, id responseObject) {
          NSDictionary *response = (NSDictionary *)responseObject;
          [[NSFileManager defaultManager] removeItemAtPath:streamingCacheFilePath error:nil];
          if (![response isKindOfClass:[NSDictionary class]]) {
              localProgress.completedUnitCount=0;
              localProgress.totalUnitCount=0;
              NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"The server returned an empty response. This usually means you need to increase the memory limit for your site.", @"")}];
              if (failure) {
                  failure(error);
              }              
          } else {
              localProgress.completedUnitCount=localProgress.totalUnitCount;
              RemoteMedia * remoteMedia = [self remoteMediaFromUploadXMLRPCDictionary:response];
              if (success){
                  success(remoteMedia);
              }
          }
      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
          localProgress.completedUnitCount=0;
          localProgress.totalUnitCount=0;
          [[NSFileManager defaultManager] removeItemAtPath:streamingCacheFilePath error:nil];
          if (failure) {
              failure(error);
          }
      }];
    
    // Setup progress object
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        localProgress.completedUnitCount+=bytesWritten;
    }];
    unsigned long long size = [[request valueForHTTPHeaderField:@"Content-Length"] longLongValue];
    // Adding some extra time because after the upload is done the backend takes some time to process the data sent
    localProgress.totalUnitCount = size+1;
    localProgress.cancellable = YES;
    localProgress.pausable = NO;
    localProgress.cancellationHandler = ^(){
        [operation cancel];
    };
    
    if (progress) {
        *progress = localProgress;
    }
    
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
