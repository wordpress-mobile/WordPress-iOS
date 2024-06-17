#import "MediaServiceRemoteREST.h"
#import "RemoteMedia.h"
#import "WPKit-Swift.h"
@import WordPressShared;
@import NSObject_SafeExpectations;

const NSInteger WPRestErrorCodeMediaNew = 10;

@implementation MediaServiceRemoteREST

- (void)getMediaWithID:(NSNumber *)mediaID
               success:(void (^)(RemoteMedia *remoteMedia))success
               failure:(void (^)(NSError *error))failure
{
    NSString *apiPath = [NSString stringWithFormat:@"sites/%@/media/%@", self.siteID, mediaID];
    NSString *requestUrl = [self pathForEndpoint:apiPath
                                     withVersion:WordPressComRESTAPIVersion_1_1];
    
    NSDictionary * parameters = @{};
    
    [self.wordPressComRESTAPI get:requestUrl parameters:parameters success:^(id responseObject, NSHTTPURLResponse *response) {
        if (success) {
            NSDictionary *response = (NSDictionary *)responseObject;
            success([MediaServiceRemoteREST remoteMediaFromJSONDictionary:response]);
        }
    } failure:^(NSError *error, NSHTTPURLResponse *response) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)getMediaLibraryWithPageLoad:(void (^)(NSArray *))pageLoad
                           success:(void (^)(NSArray *))success
                           failure:(void (^)(NSError *))failure
{
    NSMutableArray *media = [NSMutableArray array];
    NSString *path = [NSString stringWithFormat:@"sites/%@/media", self.siteID];
    [self getMediaLibraryPage:nil
                        media:media
                         path:path
                     pageLoad:pageLoad
                      success:success
                      failure:failure];
}

- (void)getMediaLibraryPage:(NSString *)pageHandle
                      media:(NSMutableArray *)media
                       path:(NSString *)path
                   pageLoad:(void (^)(NSArray *))pageLoad
                    success:(void (^)(NSArray *))success
                    failure:(void (^)(NSError *))failure
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"number"] = @100;
    if ([pageHandle length]) {
        parameters[@"page_handle"] = pageHandle;
    }
    
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:WordPressComRESTAPIVersion_1_1];
    
    [self.wordPressComRESTAPI get:requestUrl
       parameters:[NSDictionary dictionaryWithDictionary:parameters]
          success:^(id responseObject, NSHTTPURLResponse *response) {
              NSArray *mediaItems = responseObject[@"media"];
              NSArray *pageItems = [MediaServiceRemoteREST remoteMediaFromJSONArray:mediaItems];
              [media addObjectsFromArray:pageItems];
              NSDictionary *meta = responseObject[@"meta"];
              NSString *nextPage = meta[@"next_page"];
              if (nextPage.length) {
                  if (pageItems.count) {
                      if(pageLoad) {
                          pageLoad(pageItems);
                      }
                  }
                  [self getMediaLibraryPage:nextPage
                                      media:media
                                       path:path
                                   pageLoad:pageLoad
                                    success:success
                                    failure:failure];
              } else if (success) {
                  success([NSArray arrayWithArray:media]);
              }
          }
          failure:^(NSError *error, NSHTTPURLResponse *response) {
              if (failure) {
                  failure(error);
              }
          }];
}

- (void)getMediaLibraryCountForType:(NSString *)mediaType
                        withSuccess:(void (^)(NSInteger))success
                            failure:(void (^)(NSError *))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/media", self.siteID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:WordPressComRESTAPIVersion_1_1];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:@{ @"number" : @1 }];
    if (mediaType) {
        parameters[@"mime_type"] = mediaType;
    }
    
    [self.wordPressComRESTAPI get:requestUrl
       parameters:[NSDictionary dictionaryWithDictionary:parameters]
          success:^(id responseObject, NSHTTPURLResponse *response) {
              NSDictionary *jsonDictionary = (NSDictionary *)responseObject;
              NSNumber *count = [jsonDictionary numberForKey:@"found"];
              if (success) {
                  success([count intValue]);
              }
          }
          failure:^(NSError *error, NSHTTPURLResponse *response) {
              if (failure) {
                  failure(error);
              }
          }];
}

- (void)uploadMedia:(NSArray *)mediaItems
    requestEnqueued:(void (^)(NSNumber *taskID))requestEnqueued
            success:(void (^)(NSArray *remoteMedia))success
            failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(mediaItems);

    NSString *apiPath = [NSString stringWithFormat:@"sites/%@/media/new", self.siteID];
    NSString *requestUrl = [self pathForEndpoint:apiPath
                                     withVersion:WordPressComRESTAPIVersion_1_1];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:@{}];
    NSMutableArray *fileParts = [NSMutableArray array];

    for (RemoteMedia *remoteMedia in mediaItems) {
        NSString *type = remoteMedia.mimeType;
        NSString *filename = remoteMedia.file;
        if (remoteMedia.postID != nil && [remoteMedia.postID compare:@(0)] == NSOrderedDescending) {
            parameters[@"attrs[0][parent_id]"] = remoteMedia.postID;
        }
        FilePart *filePart = [[FilePart alloc] initWithParameterName:@"media[]" url:remoteMedia.localURL fileName:filename mimeType:type];
        [fileParts addObject:filePart];
    }

    [self.wordPressComRESTAPI multipartPOST:requestUrl
                                 parameters:parameters
                                  fileParts:fileParts
                            requestEnqueued:^(NSNumber *taskID) {
                                if (requestEnqueued) {
                                    requestEnqueued(taskID);
                                }
                            } success:^(id  _Nonnull responseObject, NSHTTPURLResponse * _Nullable httpResponse) {
                                NSDictionary *response = (NSDictionary *)responseObject;
                                NSArray *errorList = response[@"errors"];
                                NSArray *mediaList = response[@"media"];
                                NSMutableArray *returnedRemoteMedia = [NSMutableArray array];

                                if (mediaList.count > 0) {
                                    for (NSDictionary *returnedMediaDict in mediaList) {
                                        RemoteMedia *remoteMedia = [MediaServiceRemoteREST remoteMediaFromJSONDictionary:returnedMediaDict];
                                        [returnedRemoteMedia addObject:remoteMedia];
                                    }

                                    if (success) {
                                        success(returnedRemoteMedia);
                                    }
                                } else {
                                    NSError *error = [self processMediaUploadErrors:errorList];
                                    if (failure) {
                                        failure(error);
                                    }
                                }
                            } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
                                WPKitLogDebug(@"Error uploading multiple media files: %@", [error localizedDescription]);
                                if (failure) {
                                    failure(error);
                                }
                            }];

}

- (void)uploadMedia:(RemoteMedia *)media
           progress:(NSProgress **)progress
            success:(void (^)(RemoteMedia *remoteMedia))success
            failure:(void (^)(NSError *error))failure
{
    NSString *type = media.mimeType;
    NSString *filename = media.file;

    NSString *apiPath = [NSString stringWithFormat:@"sites/%@/media/new", self.siteID];
    NSString *requestUrl = [self pathForEndpoint:apiPath
                                     withVersion:WordPressComRESTAPIVersion_1_1];

    NSDictionary *parameters = [self parametersForUploadMedia:media];

    if (media.localURL == nil || filename == nil || type == nil) {
        if (failure) {
            NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                                 code:NSURLErrorFileDoesNotExist
                                             userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Media doesn't have an associated file to upload.", @"Error message to show to users when trying to upload a media object with no local file associated")}];
            failure(error);
        }
        return;
    }
    FilePart *filePart = [[FilePart alloc] initWithParameterName:@"media[]" url:media.localURL fileName:filename mimeType:type];
    __block NSProgress *localProgress = [self.wordPressComRESTAPI multipartPOST:requestUrl
                                                                     parameters:parameters
                                                                      fileParts:@[filePart]
                                                                requestEnqueued:nil
                                                                        success:^(id  _Nonnull responseObject, NSHTTPURLResponse * _Nullable httpResponse) {
                                                                            NSDictionary *response = (NSDictionary *)responseObject;
                                                                            NSArray *errorList = response[@"errors"];
                                                                            NSArray *mediaList = response[@"media"];
                                                                            if (mediaList.count > 0){
                                                                                RemoteMedia *remoteMedia = [MediaServiceRemoteREST remoteMediaFromJSONDictionary:mediaList[0]];
                                                                                if (success) {
                                                                                    success(remoteMedia);
                                                                                }
                                                                            } else {
                                                                                NSError *error = [self processMediaUploadErrors:errorList];
                                                                                if (failure) {
                                                                                    failure(error);
                                                                                }
                                                                            }

                                                                        } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
                                                                            WPKitLogDebug(@"Error uploading file: %@", [error localizedDescription]);
                                                                            if (failure) {
                                                                                failure(error);
                                                                            }
                                                                        }];

    *progress = localProgress;
}

- (NSError *)processMediaUploadErrors:(NSArray *)errorList {
    WPKitLogDebug(@"Error uploading file: %@", errorList);
    NSError * error = nil;
    if (errorList.count > 0) {
        NSString *errorMessage = [errorList.firstObject description];
        if ([errorList.firstObject isKindOfClass:NSDictionary.class]) {
            NSDictionary *errorInfo = errorList.firstObject;
            errorMessage = errorInfo[@"message"];
        }
        NSDictionary *errorDictionary = @{NSLocalizedDescriptionKey: errorMessage};
        error = [[NSError alloc] initWithDomain:WordPressComRestApiErrorDomain
                                           code:WordPressComRestApiErrorCodeUploadFailed
                                       userInfo:errorDictionary];
    }
    return error;
}

- (void)updateMedia:(RemoteMedia *)media
            success:(void (^)(RemoteMedia *remoteMedia))success
            failure:(void (^)(NSError *error))failure
{
    NSParameterAssert([media isKindOfClass:[RemoteMedia class]]);

    NSString *path = [NSString stringWithFormat:@"sites/%@/media/%@", self.siteID, media.mediaID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:WordPressComRESTAPIVersion_1_1];

    NSDictionary *parameters = [self parametersFromRemoteMedia:media];

    [self.wordPressComRESTAPI post:requestUrl
        parameters:parameters
           success:^(id responseObject, NSHTTPURLResponse *response) {
               RemoteMedia *media = [MediaServiceRemoteREST remoteMediaFromJSONDictionary:responseObject];
               if (success) {
                   success(media);
               }
           } failure:^(NSError *error, NSHTTPURLResponse *response) {
               if (failure) {
                   failure(error);
               }
           }];
}

- (void)deleteMedia:(RemoteMedia *)media
            success:(void (^)(void))success
            failure:(void (^)(NSError *))failure
{
    NSParameterAssert([media isKindOfClass:[RemoteMedia class]]);

    NSString *path = [NSString stringWithFormat:@"sites/%@/media/%@/delete", self.siteID, media.mediaID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:WordPressComRESTAPIVersion_1_1];

    [self.wordPressComRESTAPI post:requestUrl
                        parameters:nil
                           success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                               NSDictionary *response = (NSDictionary *)responseObject;
                               NSString *status = [response stringForKey:@"status"];
                               if ([status isEqualToString:@"deleted"]) {
                                   if (success) {
                                       success();
                                   }
                               } else {
                                   if (failure) {
                                       NSError *error = [[NSError alloc] initWithDomain:WordPressComRestApiErrorDomain
                                                                                   code:WordPressComRestApiErrorCodeUnknown
                                                                               userInfo:nil];
                                       failure(error);
                                   }
                               }
                           } failure:^(NSError *error, NSHTTPURLResponse *response) {
                               if (failure) {
                                   failure(error);
                               }
                           }];
}

-(void)getMetadataFromVideoPressID:(NSString *)videoPressID
                     isSitePrivate:(BOOL)isSitePrivate
                           success:(void (^)(RemoteVideoPressVideo *metadata))success
                           failure:(void (^)(NSError *))failure
{
    NSString *path = [NSString stringWithFormat:@"videos/%@", videoPressID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:WordPressComRESTAPIVersion_1_1];
    
    [self.wordPressComRESTAPI get:requestUrl
                       parameters:nil
                          success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
        NSDictionary *response = (NSDictionary *)responseObject;
        RemoteVideoPressVideo *video = [[RemoteVideoPressVideo alloc] initWithDictionary:response id:videoPressID];

        BOOL needsToken = video.privacySetting == VideoPressPrivacySettingIsPrivate || (video.privacySetting == VideoPressPrivacySettingSiteDefault && isSitePrivate);
        if(needsToken) {
            [self getVideoPressToken:videoPressID success:^(NSString *token) {
                video.token = token;
                if (success) {
                    success(video);
                }
            } failure:^(NSError * error) {
                if (failure) {
                    failure(error);
                }
            }];
        }
        else {
            if (success) {
                success(video);
            }
        }
    } failure:^(NSError *error, NSHTTPURLResponse *response) {
        if (failure) {
            failure(error);
        }
    }];
}

-(void)getVideoPressToken:(NSString *)videoPressID
                           success:(void (^)(NSString *token))success
                           failure:(void (^)(NSError *))failure
{
    
    NSString *path = [NSString stringWithFormat:@"sites/%@/media/videopress-playback-jwt/%@", self.siteID, videoPressID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:WordPressComRESTAPIVersion_2_0];

    [self.wordPressComRESTAPI post:requestUrl
                        parameters:nil
                           success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                               NSDictionary *response = (NSDictionary *)responseObject;
                               NSString *token = [response stringForKey:@"metadata_token"];
                               if (token) {
                                   if (success) {
                                       success(token);
                                   }
                               } else {
                                   if (failure) {
                                       NSError *error = [[NSError alloc] initWithDomain:WordPressComRestApiErrorDomain
                                                                                   code:WordPressComRestApiErrorCodeUnknown
                                                                               userInfo:nil];
                                       failure(error);
                                   }
                               }
                           } failure:^(NSError *error, NSHTTPURLResponse *response) {
                               if (failure) {
                                   failure(error);
                               }
                           }];
}

+ (NSArray *)remoteMediaFromJSONArray:(NSArray *)jsonMedia
{
    return [jsonMedia wp_map:^id(NSDictionary *json) {
        return [self remoteMediaFromJSONDictionary:json];
    }];
}

+ (RemoteMedia *)remoteMediaFromJSONDictionary:(NSDictionary *)jsonMedia
{
    RemoteMedia * remoteMedia=[[RemoteMedia alloc] init];
    remoteMedia.mediaID =  [jsonMedia numberForKey:@"ID"];
    remoteMedia.url = [NSURL URLWithString:[jsonMedia stringForKey:@"URL"]];
    remoteMedia.guid = [NSURL URLWithString:[jsonMedia stringForKey:@"guid"]];
    remoteMedia.date = [NSDate dateWithWordPressComJSONString:jsonMedia[@"date"]];
    remoteMedia.postID = [jsonMedia numberForKey:@"post_ID"];
    remoteMedia.file = [jsonMedia stringForKey:@"file"];
    remoteMedia.largeURL = [NSURL URLWithString:[jsonMedia valueForKeyPath :@"thumbnails.large"]];
    remoteMedia.mediumURL = [NSURL URLWithString:[jsonMedia valueForKeyPath :@"thumbnails.medium"]];
    remoteMedia.mimeType = [jsonMedia stringForKey:@"mime_type"];
    remoteMedia.extension = [jsonMedia stringForKey:@"extension"];
    remoteMedia.title = [jsonMedia stringForKey:@"title"];
    remoteMedia.caption = [jsonMedia stringForKey:@"caption"];
    remoteMedia.descriptionText = [jsonMedia stringForKey:@"description"];
    remoteMedia.alt = [jsonMedia stringForKey:@"alt"];
    remoteMedia.height = [jsonMedia numberForKey:@"height"];
    remoteMedia.width = [jsonMedia numberForKey:@"width"];
    remoteMedia.exif = [jsonMedia dictionaryForKey:@"exif"];
    remoteMedia.remoteThumbnailURL = [jsonMedia stringForKeyPath:@"thumbnails.fmt_std"];
    remoteMedia.videopressGUID = [jsonMedia stringForKey:@"videopress_guid"];
    remoteMedia.length = [jsonMedia numberForKey:@"length"];
    return remoteMedia;
}

- (NSDictionary *)parametersFromRemoteMedia:(RemoteMedia *)remoteMedia
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];

    if (remoteMedia.postID != nil) {
        parameters[@"parent_id"] = remoteMedia.postID;
    }
    if (remoteMedia.title != nil) {
        parameters[@"title"] = remoteMedia.title;
    }

    if (remoteMedia.caption != nil) {
        parameters[@"caption"] = remoteMedia.caption;
    }

    if (remoteMedia.descriptionText != nil) {
        parameters[@"description"] = remoteMedia.descriptionText;
    }
    
    if (remoteMedia.alt != nil) {
        parameters[@"alt"] = remoteMedia.alt;
    }

    return [NSDictionary dictionaryWithDictionary:parameters];
}

- (NSDictionary *)parametersForUploadMedia:(RemoteMedia *)media
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];

    if (media.caption != nil) {
        parameters[@"attrs[0][caption]"] = media.caption;
    }
    if (media.postID != nil && [media.postID compare:@(0)] == NSOrderedDescending) {
        parameters[@"attrs[0][parent_id]"] = media.postID;
    }

    return [NSDictionary dictionaryWithDictionary:parameters];
}

@end
