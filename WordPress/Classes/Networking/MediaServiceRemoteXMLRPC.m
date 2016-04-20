#import "MediaServiceRemoteXMLRPC.h"
#import "RemoteMedia.h"
#import <WordPressApi/WPXMLRPCClient.h>

@implementation MediaServiceRemoteXMLRPC

- (void)getMediaWithID:(NSNumber *)mediaID
               success:(void (^)(RemoteMedia *remoteMedia))success
               failure:(void (^)(NSError *error))failure
{
    NSArray *parameters = [self XMLRPCArgumentsWithExtra:mediaID];
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

- (void)getMediaLibraryWithSuccess:(void (^)(NSArray *))success
                           failure:(void (^)(NSError *))failure
{
    NSArray *parameters = [self defaultXMLRPCArguments];
    [self.api callMethod:@"wp.getMediaLibrary"
              parameters:parameters
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     NSAssert([responseObject isKindOfClass:[NSArray class]], @"Response should be an array.");
                     if (success) {
                         success([self remoteMediaFromXMLRPCArray:responseObject]);
                     }
                 }
                 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     if (failure) {
                         failure(error);
                     }
                 }];
}

- (void)getMediaLibraryCountWithSuccess:(void (^)(NSInteger))success
                                failure:(void (^)(NSError *))failure
{
    NSArray *parameters = [self defaultXMLRPCArguments];
    [self.api callMethod:@"wp.getMediaLibrary"
              parameters:parameters
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     NSAssert([responseObject isKindOfClass:[NSArray class]], @"Response should be an array.");
                     if (success) {
                         success([responseObject count]);
                     }
                 }
                 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     if (failure) {
                         failure(error);
                     }
                 }];
}


- (NSURLCredential *)findCredentialForHost:(NSString *)host port:(NSInteger)port
{
    __block NSURLCredential *foundCredential = nil;
    [[[NSURLCredentialStorage sharedCredentialStorage] allCredentials] enumerateKeysAndObjectsUsingBlock:^(NSURLProtectionSpace *ps, NSDictionary *dict, BOOL *stop) {
        [dict enumerateKeysAndObjectsUsingBlock:^(id key, NSURLCredential *credential, BOOL *stop) {
            if ([[ps host] isEqualToString:host] && [ps port] == port)
            
            {
                foundCredential = credential;
                *stop = YES;
            }
        }];
        if (foundCredential) {
            *stop = YES;
        }
    }];
    return foundCredential;
}

/** 
 Adds a basic auth header to a request if a credential is stored for that specific host.
 
 The credentials will only be added if a set of credentials for the request host are stored on the shared credential storage
 @param request, the request to where the authentication information will be added.
 */
- (void)addBasicAuthCredentialsIfAvailableToRequest:(NSMutableURLRequest *)request
{
    NSInteger port = [[request.URL port] integerValue];
    if (port == 0) {
        port = 80;
    }

    NSURLCredential *credential = [self findCredentialForHost:request.URL.host port:port];
    if (credential) {
        NSString *authStr = [NSString stringWithFormat:@"%@:%@", [credential user], [credential password]];
        NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
        NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]];
        [request setValue:authValue forHTTPHeaderField:@"Authorization"];
    }
}

- (void)createMedia:(RemoteMedia *)media
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
    NSArray *parameters = [self XMLRPCArgumentsWithExtra:data];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *directory = [paths objectAtIndex:0];
    NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *streamingCacheFilePath = [directory stringByAppendingPathComponent:guid];
    
    NSMutableURLRequest *request = [self.api streamingRequestWithMethod:@"wp.uploadFile" parameters:parameters usingFilePathForCache:streamingCacheFilePath];
    
    [self addBasicAuthCredentialsIfAvailableToRequest:request];
    
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

- (NSArray *)remoteMediaFromXMLRPCArray:(NSArray *)xmlrpcArray
{
    return [xmlrpcArray wp_map:^id(NSDictionary *xmlrpcMedia) {
        return [self remoteMediaFromXMLRPCDictionary:xmlrpcMedia];
    }];
}

- (RemoteMedia *)remoteMediaFromXMLRPCDictionary:(NSDictionary*)xmlRPC
{
    RemoteMedia * remoteMedia = [[RemoteMedia alloc] init];
    remoteMedia.url = [NSURL URLWithString:[xmlRPC stringForKey:@"link"]];
    remoteMedia.title = [xmlRPC stringForKey:@"title"];
    remoteMedia.width = [xmlRPC numberForKeyPath:@"metadata.width"];
    remoteMedia.height = [xmlRPC numberForKeyPath:@"metadata.height"];
    remoteMedia.mediaID = [xmlRPC numberForKey:@"attachment_id"];
    remoteMedia.mimeType = [xmlRPC stringForKeyPath:@"metadata.mime_type"];
    remoteMedia.file = [[xmlRPC objectForKeyPath:@"link"] lastPathComponent];
    remoteMedia.date = xmlRPC[@"date_created_gmt"];
    remoteMedia.caption = [xmlRPC stringForKey:@"caption"];
    remoteMedia.descriptionText = [xmlRPC stringForKey:@"description"];
    remoteMedia.extension = [remoteMedia.file pathExtension];
    remoteMedia.length = [xmlRPC numberForKeyPath:@"metadata.length"];
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
