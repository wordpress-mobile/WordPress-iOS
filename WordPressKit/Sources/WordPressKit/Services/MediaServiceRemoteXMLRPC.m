#import "MediaServiceRemoteXMLRPC.h"
#import "RemoteMedia.h"
#import "WPKit-Swift.h"

@import WordPressShared;
@import NSObject_SafeExpectations;

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

- (void)getMediaLibraryWithPageLoad:(void (^)(NSArray *))pageLoad
                           success:(void (^)(NSArray *))success
                           failure:(void (^)(NSError *))failure
{
    [self getMediaLibraryStartOffset:0 media:@[] pageLoad:pageLoad success:success failure:failure];
}

- (void)getMediaLibraryStartOffset:(NSUInteger)offset
                             media:(NSArray *)media
                          pageLoad:(void (^)(NSArray *))pageLoad
                           success:(void (^)(NSArray *))success
                           failure:(void (^)(NSError *))failure
{
    NSInteger pageSize = 100;
    NSDictionary *filter = @{
                                @"number": @(pageSize),
                                @"offset": @(offset)
                            };
    NSArray *parameters = [self XMLRPCArgumentsWithExtra:filter];

    [self.api callMethod:@"wp.getMediaLibrary"
              parameters:parameters
                 success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                     NSAssert([responseObject isKindOfClass:[NSArray class]], @"Response should be an array.");
                     if (!success) {
                         return;
                     }
                     NSArray *pageMedia = [self remoteMediaFromXMLRPCArray:responseObject];
                     NSArray *resultMedia = [media arrayByAddingObjectsFromArray:pageMedia];
                     // Did we got all the items we requested or it's finished?
                     if (pageMedia.count < pageSize) {
                         success(resultMedia);
                         return;
                     }
                     if(pageLoad) {
                        pageLoad(pageMedia);
                     }
                     NSUInteger newOffset = offset + pageSize;
                     [self getMediaLibraryStartOffset:newOffset media:resultMedia pageLoad:pageLoad success: success failure: failure];                     
                 }
                 failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
                     if (failure) {
                         failure(error);
                     }
                 }];
}

- (void)getMediaLibraryCountForType:(NSString *)mediaType
                        withSuccess:(void (^)(NSInteger))success
                            failure:(void (^)(NSError *))failure
{
    NSDictionary *data = @{};
    if (mediaType) {
        data = @{@"filter":@{ @"mime_type": mediaType }};
    }
    NSArray *parameters = [self XMLRPCArgumentsWithExtra:data];
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
 @param request     The request to where the authentication information will be added.
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

- (void)uploadMedia:(RemoteMedia *)media
           progress:(NSProgress **)progress
            success:(void (^)(RemoteMedia *remoteMedia))success
            failure:(void (^)(NSError *error))failure
{
    NSString *type = media.mimeType;
    NSString *filename = media.file;
    if (media.localURL == nil || filename == nil || type == nil) {
        if (failure) {
            NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                                 code:NSURLErrorFileDoesNotExist
                                             userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Media doesn't have an associated file to upload.", @"Error message to show to users when trying to upload a media object with no local file associated")}];
            failure(error);
        }
        return;
    }
    NSMutableDictionary *data = [NSMutableDictionary dictionaryWithDictionary:@{
                           @"name": filename,
                           @"type": type,
                           @"bits": [NSInputStream inputStreamWithFileAtPath:media.localURL.path],
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
              NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"The server returned an empty response. This usually means you need to increase the memory limit for your site.", @"")}];
              if (failure) {
                  failure(error);
              }              
          } else {
              localProgress.completedUnitCount=localProgress.totalUnitCount;
              RemoteMedia * remoteMedia = [self remoteMediaFromXMLRPCDictionary:response];
              if (success){
                  success(remoteMedia);
              }
          }
      } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
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
    NSParameterAssert([media.mediaID longLongValue] > 0);

    NSMutableDictionary *content = [NSMutableDictionary dictionary];

    if (media.title != nil) {
        content[@"post_title"] = media.title;
    }

    if (media.caption != nil) {
        content[@"post_excerpt"] = media.caption;
    }

    if (media.descriptionText != nil) {
        content[@"post_content"] = media.descriptionText;
    }

    NSArray *extraDefaults = @[media.mediaID];
    NSArray *parameters = [self XMLRPCArgumentsWithExtraDefaults:extraDefaults andExtra:content];

    [self.api callMethod:@"wp.editPost"
              parameters:parameters
                 success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
        BOOL updated = [responseObject boolValue];
        if (updated) {
            if (success) {
                success(media);
            }
        } else {
            if (failure) {
                NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUnknown userInfo:nil];
                failure(error);
            }
        }
    } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)deleteMedia:(RemoteMedia *)media
            success:(void (^)(void))success
            failure:(void (^)(NSError *))failure
{
    NSParameterAssert([media.mediaID longLongValue] > 0);

    NSArray *parameters = [self XMLRPCArgumentsWithExtra:media.mediaID];
    [self.api callMethod:@"wp.deleteFile"
              parameters:parameters
                 success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                     BOOL deleted = [responseObject boolValue];
                     if (deleted) {
                         if (success) {
                             success();
                         }
                     } else {
                         if (failure) {
                             NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUnknown userInfo:nil];
                             failure(error);
                         }
                     }
                 } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
                     if (failure) {
                         failure(error);
                     }
                 }];
}

-(void)getMetadataFromVideoPressID:(NSString *)videoPressID
                     isSitePrivate:(BOOL)includeToken
                           success:(void (^)(RemoteVideoPressVideo *video))success
                           failure:(void (^)(NSError *))failure
{
    // ⚠️ The endpoint used for fetching the metadata  is not available in XML-RPC.
    if (failure) {
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                             code:NSURLErrorUnsupportedURL
                                         userInfo:nil];
        failure(error);
    }
}

-(void)getVideoPressToken:(NSString *)videoPressID
                           success:(void (^)(NSString *token))success
                           failure:(void (^)(NSError *))failure
{
    // The endpoint `wpcom/v2/sites/<wpcom-site>/media/videopress-playback-jwt/<videopress-guid>` is not available in XML-RPC.
    if (failure) {
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                             code:NSURLErrorUnsupportedURL
                                         userInfo:nil];
        failure(error);
    }
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
    remoteMedia.url = [NSURL URLWithString:[xmlRPC stringForKey:@"link"]] ?: [NSURL URLWithString:[xmlRPC stringForKey:@"url"]];
    remoteMedia.title = [xmlRPC stringForKey:@"title"];
    remoteMedia.width = [xmlRPC numberForKeyPath:@"metadata.width"];
    remoteMedia.height = [xmlRPC numberForKeyPath:@"metadata.height"];
    remoteMedia.mediaID = [xmlRPC numberForKey:@"attachment_id"] ?: [xmlRPC numberForKey:@"id"];
    remoteMedia.mimeType = [xmlRPC stringForKeyPath:@"metadata.mime_type"] ?: [xmlRPC stringForKey:@"type"];
    NSString *link = nil;
    if ([[xmlRPC objectForKeyPath:@"link"] isKindOfClass:NSDictionary.class]) {
        NSDictionary *linkDictionary = (NSDictionary *)[xmlRPC objectForKeyPath:@"link"];
        link = [linkDictionary stringForKeyPath:@"url"];
    } else {
        link = [xmlRPC stringForKeyPath:@"link"];
    }
    remoteMedia.file = [link lastPathComponent] ?: [[xmlRPC objectForKeyPath:@"file"] lastPathComponent];

    if ([xmlRPC stringForKeyPath:@"metadata.sizes.large.file"] != nil) {
        remoteMedia.largeURL = [NSURL URLWithString: [NSString stringWithFormat:@"%@%@", remoteMedia.url.URLByDeletingLastPathComponent, [xmlRPC stringForKeyPath:@"metadata.sizes.large.file"]]];
    }

    if ([xmlRPC stringForKeyPath:@"metadata.sizes.medium.file"] != nil) {
        remoteMedia.mediumURL = [NSURL URLWithString: [NSString stringWithFormat:@"%@%@", remoteMedia.url.URLByDeletingLastPathComponent, [xmlRPC stringForKeyPath:@"metadata.sizes.medium.file"]]];
    }

    if (xmlRPC[@"date_created_gmt"] != nil) {
        remoteMedia.date = xmlRPC[@"date_created_gmt"];
    }

    remoteMedia.caption = [xmlRPC stringForKey:@"caption"];
    remoteMedia.descriptionText = [xmlRPC stringForKey:@"description"];
    // Sergio (2017-10-26): This field isn't returned by the XMLRPC API so we assuming empty string
    remoteMedia.alt = @"";
    remoteMedia.extension = [remoteMedia.file pathExtension];
    remoteMedia.length = [xmlRPC numberForKeyPath:@"metadata.length"];

    NSNumber *parent = [xmlRPC numberForKeyPath:@"parent"];
    if ([parent integerValue] > 0) {
        remoteMedia.postID = parent;
    }

    return remoteMedia;
}

@end
