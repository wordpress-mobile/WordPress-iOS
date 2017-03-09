#import "MediaServiceRemoteXMLRPC.h"
#import "RemoteMedia.h"
#import "WordPress-Swift.h"

@implementation MediaServiceRemoteXMLRPC

- (void)getMediaWithID:(NSNumber *)mediaID
               success:(void (^)(RemoteMedia *remoteMedia))success
               failure:(void (^)(NSError *error))failure
{
    NSArray *parameters = [self XMLRPCArgumentsWithExtra:mediaID];
    [self.api callMethod:@"wp.getMediaItem"
              parameters:parameters
                 success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                     if (success) {
                        NSDictionary * xmlRPCDictionary = (NSDictionary *)responseObject;
                        RemoteMedia * remoteMedia = [self remoteMediaFromXMLRPCDictionary:xmlRPCDictionary];
                        success(remoteMedia);
                     }
                 } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
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
                 success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                     NSAssert([responseObject isKindOfClass:[NSArray class]], @"Response should be an array.");
                     if (success) {
                         success([self remoteMediaFromXMLRPCArray:responseObject]);
                     }
                 }
                 failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
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
                 success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                     NSAssert([responseObject isKindOfClass:[NSArray class]], @"Response should be an array.");
                     if (success) {
                         success([responseObject count]);
                     }
                 }
                 failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
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
    NSString *path = media.localURL;
    NSString *type = media.mimeType;
    NSString *filename = media.file;
    
    NSMutableDictionary *data = [NSMutableDictionary dictionaryWithDictionary:@{
                           @"name": filename,
                           @"type": type,
                           @"bits": [NSInputStream inputStreamWithFileAtPath:path],
                           }];
    if ([media.postID compare:@(0)] == NSOrderedDescending) {
        data[@"post_id"] = media.postID;
    }

    NSArray *parameters = [self XMLRPCArgumentsWithExtra:data];

    __block NSProgress *localProgress = [self.api streamCallMethod:@"wp.uploadFile"
                                                parameters:parameters
                                                   success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
          NSDictionary *response = (NSDictionary *)responseObject;
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
      } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
          localProgress.completedUnitCount=0;
          localProgress.totalUnitCount=0;          
          if (failure) {
              failure(error);
          }
      }];

    
    if (progress) {
        *progress = localProgress;
    }
}

- (void)updateMedia:(RemoteMedia *)media
            success:(void (^)(RemoteMedia *remoteMedia))success
            failure:(void (^)(NSError *error))failure
{
    //HACK: Sergio Estevao: 2016-04-06 this option doens't exist on XML-RPC so we will always say that all was good
    if (success) {
        success(media);
    }
}

- (void)deleteMedia:(RemoteMedia *)media
            success:(void (^)())success
            failure:(void (^)(NSError *))failure
{
    NSParameterAssert([media.mediaID longLongValue] > 0);

    NSArray *parameters = [self XMLRPCArgumentsWithExtra:media.mediaID];
    [self.api callMethod:@"wp.deleteFile"
              parameters:parameters
                 success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                     if (success) {
                         success();
                     }
                 } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
                     if (failure) {
                         failure(error);
                     }
                 }];
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
    remoteMedia.postID = [xmlRPC numberForKeyPath:@"parent"];
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
    if (xmlRPC[@"date_created_gmt"] != nil) {
        remoteMedia.date = xmlRPC[@"date_created_gmt"];
    }
    return remoteMedia;
}

@end
