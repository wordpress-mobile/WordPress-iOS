#import "MediaServiceRemoteREST.h"
#import "RemoteMedia.h"
#import "Logging.h"
#import <WordPressKit/WordPressKit-Swift.h>
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
                                     withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];
    
    NSDictionary * parameters = @{};
    
    [self.wordPressComRestApi GET:requestUrl parameters:parameters success:^(id responseObject, NSHTTPURLResponse *response) {
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

- (void)getMediaLibraryWithSuccess:(void (^)(NSArray *))success
                           failure:(void (^)(NSError *))failure
{
    NSMutableArray *media = [NSMutableArray array];
    NSString *path = [NSString stringWithFormat:@"sites/%@/media", self.siteID];
    [self getMediaLibraryPage:nil
                        media:media
                         path:path
                      success:success
                      failure:failure];
}

- (void)getMediaLibraryPage:(NSString *)pageHandle
                      media:(NSMutableArray *)media
                       path:(NSString *)path
                    success:(void (^)(NSArray *))success
                    failure:(void (^)(NSError *))failure
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"number"] = @100;
    if ([pageHandle length]) {
        parameters[@"page_handle"] = pageHandle;
    }
    
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];
    
    [self.wordPressComRestApi GET:requestUrl
       parameters:[NSDictionary dictionaryWithDictionary:parameters]
          success:^(id responseObject, NSHTTPURLResponse *response) {
              NSArray *mediaItems = responseObject[@"media"];
              NSArray *pageItems = [MediaServiceRemoteREST remoteMediaFromJSONArray:mediaItems];
              if (pageItems.count) {
                  [media addObjectsFromArray:pageItems];
              }
              NSDictionary *meta = responseObject[@"meta"];
              NSString *nextPage = meta[@"next_page"];
              if (nextPage.length) {
                  [self getMediaLibraryPage:nextPage
                                      media:media
                                       path:path
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
                                     withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:@{ @"number" : @1 }];
    if (mediaType) {
        parameters[@"media_type"] = mediaType;
    }
    
    [self.wordPressComRestApi GET:requestUrl
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
                                     withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:@{}];
    NSMutableArray *fileParts = [NSMutableArray array];

    for (RemoteMedia *remoteMedia in mediaItems) {
        NSString *type = remoteMedia.mimeType;
        NSString *filename = remoteMedia.file;
        if (remoteMedia.postID != nil && [remoteMedia.postID compare:@(0)] == NSOrderedDescending) {
            parameters[@"attrs[0][parent_id]"] = remoteMedia.postID;
        }
        FilePart *filePart = [[FilePart alloc] initWithParameterName:@"media[]" url:remoteMedia.localURL filename:filename mimeType:type];
        [fileParts addObject:filePart];
    }

    [self.wordPressComRestApi multipartPOST:requestUrl
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
                                    DDLogDebug(@"Error uploading multiple media files: %@", errorList);
                                    NSError * error = nil;
                                    if (errorList.count > 0){
                                        NSDictionary * errorDictionary = @{NSLocalizedDescriptionKey: errorList[0]};
                                        error = [NSError errorWithDomain:WordPressComRestApiErrorDomain code:WordPressComRestApiErrorUploadFailed userInfo:errorDictionary];
                                    }
                                    if (failure) {
                                        failure(error);
                                    }
                                }
                            } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
                                DDLogDebug(@"Error uploading multiple media files: %@", [error localizedDescription]);
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
                                     withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:@{}];
    if (media.postID != nil && [media.postID compare:@(0)] == NSOrderedDescending) {
        parameters[@"attrs[0][parent_id]"] = media.postID;
    }
    FilePart *filePart = [[FilePart alloc] initWithParameterName:@"media[]" url:media.localURL filename:filename mimeType:type];
    __block NSProgress *localProgress = [self.wordPressComRestApi multipartPOST:requestUrl
                                                                     parameters:parameters
                                                                      fileParts:@[filePart]
                                                                requestEnqueued:nil
                                                                        success:^(id  _Nonnull responseObject, NSHTTPURLResponse * _Nullable httpResponse) {
                                                                            NSDictionary *response = (NSDictionary *)responseObject;
                                                                            NSArray * errorList = response[@"errors"];
                                                                            NSArray * mediaList = response[@"media"];
                                                                            if (mediaList.count > 0){
                                                                                RemoteMedia * remoteMedia = [MediaServiceRemoteREST remoteMediaFromJSONDictionary:mediaList[0]];
                                                                                if (success) {
                                                                                    success(remoteMedia);
                                                                                }
                                                                            } else {
                                                                                DDLogDebug(@"Error uploading file: %@", errorList);
                                                                                NSError * error = nil;
                                                                                if (errorList.count > 0){
                                                                                    NSDictionary * errorDictionary = @{NSLocalizedDescriptionKey: errorList[0]};
                                                                                    error = [NSError errorWithDomain:WordPressComRestApiErrorDomain code:WordPressComRestApiErrorUploadFailed userInfo:errorDictionary];
                                                                                }
                                                                                if (failure) {
                                                                                    failure(error);
                                                                                }
                                                                            }

                                                                        } failure:^(NSError *error, NSHTTPURLResponse *httpResponse) {
                                                                            DDLogDebug(@"Error uploading file: %@", [error localizedDescription]);
                                                                            if (failure) {
                                                                                failure(error);
                                                                            }
                                                                        }];

    *progress = localProgress;
}

- (void)updateMedia:(RemoteMedia *)media
            success:(void (^)(RemoteMedia *remoteMedia))success
            failure:(void (^)(NSError *error))failure
{
    NSParameterAssert([media isKindOfClass:[RemoteMedia class]]);

    NSString *path = [NSString stringWithFormat:@"sites/%@/media/%@", self.siteID, media.mediaID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];

    NSDictionary *parameters = [self parametersFromRemoteMedia:media];

    [self.wordPressComRestApi POST:requestUrl
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
                                     withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];

    [self.wordPressComRestApi POST:requestUrl
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
                                       NSError *error = [NSError errorWithDomain:WordPressComRestApiErrorDomain
                                                                            code:WordPressComRestApiErrorUnknown
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

-(void)getVideoURLFromVideoPressID:(NSString *)videoPressID
                           success:(void (^)(NSURL *videoURL, NSURL *posterURL))success
                           failure:(void (^)(NSError *))failure
{
    NSString *path = [NSString stringWithFormat:@"videos/%@", videoPressID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];

    [self.wordPressComRestApi GET:requestUrl
                        parameters:nil
                           success:^(id responseObject, NSHTTPURLResponse *httpResponse) {
                               NSDictionary *response = (NSDictionary *)responseObject;
                               NSString *urlString = [response stringForKey:@"original"];
                               NSString *posterURLString = [response stringForKey:@"poster"];
                               NSURL *videoURL = [NSURL URLWithString:urlString];
                               NSURL *posterURL = [NSURL URLWithString:posterURLString];
                               if (videoURL) {
                                   if (success) {
                                       success(videoURL, posterURL);
                                   }
                               } else {
                                   if (failure) {
                                       NSError *error = [NSError errorWithDomain:WordPressComRestApiErrorDomain
                                                                            code:WordPressComRestApiErrorUnknown
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

@end
