#import "MediaServiceRemoteREST.h"
#import "WordPressComApi.h"
#import "RemoteMedia.h"
#import "NSDate+WordPressJSON.h"
#import <WordPressApi/WordPressApi.h>

const NSInteger WPRestErrorCodeMediaNew = 10;

@implementation MediaServiceRemoteREST

- (void)getMediaWithID:(NSNumber *)mediaID
               success:(void (^)(RemoteMedia *remoteMedia))success
               failure:(void (^)(NSError *error))failure
{
    NSString *apiPath = [NSString stringWithFormat:@"sites/%@/media/%@", self.siteID, mediaID];
    NSString *requestUrl = [self pathForEndpoint:apiPath
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    NSDictionary * parameters = @{};
    
    [self.api GET:requestUrl parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    [self.api GET:requestUrl
       parameters:[NSDictionary dictionaryWithDictionary:parameters]
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSArray *mediaItems = responseObject[@"media"];
              NSArray *pageItems = [self remoteMediaFromJSONArray:mediaItems];
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
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              if (failure) {
                  failure(error);
              }
          }];
}

- (void)getMediaLibraryCountWithSuccess:(void (^)(NSInteger))success
                                failure:(void (^)(NSError *))failure
{
    NSString *path = [NSString stringWithFormat:@"sites/%@/media", self.siteID];
    NSString *requestUrl = [self pathForEndpoint:path
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    NSDictionary *parameters = @{ @"number" : @1 };
    
    [self.api GET:requestUrl
       parameters:[NSDictionary dictionaryWithDictionary:parameters]
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSDictionary *jsonDictionary = (NSDictionary *)responseObject;
              NSNumber *count = [jsonDictionary numberForKey:@"found"];
              if (success) {
                  success([count intValue]);
              }
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              if (failure) {
                  failure(error);
              }
          }];
}

- (void)createMedia:(RemoteMedia *)media
           progress:(NSProgress **)progress
            success:(void (^)(RemoteMedia *remoteMedia))success
            failure:(void (^)(NSError *error))failure
{
    NSProgress *localProgress = [NSProgress progressWithTotalUnitCount:2];
    NSString *path = media.localURL;
    NSString *type = media.mimeType;
    NSString *filename = media.file;

    NSString *apiPath = [NSString stringWithFormat:@"sites/%@/media/new", self.siteID];
    NSString *requestUrl = [self pathForEndpoint:apiPath
                                     withVersion:ServiceRemoteRESTApiVersion_1_1];
    
    NSMutableURLRequest *request = [self.api.requestSerializer multipartFormRequestWithMethod:@"POST"
                                                                                    URLString:[[NSURL URLWithString:requestUrl relativeToURL:self.api.baseURL] absoluteString]
                                                                                   parameters:nil
                                                                    constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
        [formData appendPartWithFileURL:url name:@"media[]" fileName:filename mimeType:type error:nil];
    } error:nil];
    
    AFHTTPRequestOperation *operation = [self.api HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *    operation, id responseObject) {
        NSDictionary *response = (NSDictionary *)responseObject;
        NSArray * errorList = response[@"error"];
        NSArray * mediaList = response[@"media"];
        if (mediaList.count > 0){
            RemoteMedia * remoteMedia = [self remoteMediaFromJSONDictionary:mediaList[0]];
            if (success) {
                success(remoteMedia);
            }
            localProgress.completedUnitCount=localProgress.totalUnitCount;
        } else {
            DDLogDebug(@"Error uploading file: %@", errorList);
            localProgress.totalUnitCount=0;
            localProgress.completedUnitCount=0;
            NSError * error = nil;
            if (errorList.count > 0){
                NSDictionary * errorDictionary = @{NSLocalizedDescriptionKey: errorList[0]};
                error = [NSError errorWithDomain:WordPressRestApiErrorDomain code:WPRestErrorCodeMediaNew userInfo:errorDictionary];
            }
            if (failure) {
                failure(error);
            }
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogDebug(@"Error uploading file: %@", [error localizedDescription]);
        localProgress.totalUnitCount=0;
        localProgress.completedUnitCount=0;
        if (failure) {
            failure(error);
        }
    }];

    // Setup progress object
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        localProgress.completedUnitCount +=bytesWritten;
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

- (NSArray *)remoteMediaFromJSONArray:(NSArray *)jsonMedia
{
    return [jsonMedia wp_map:^id(NSDictionary *json) {
        return [self remoteMediaFromJSONDictionary:json];
    }];
}

- (RemoteMedia *)remoteMediaFromJSONDictionary:(NSDictionary *)jsonMedia
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
    remoteMedia.height = [jsonMedia numberForKey:@"height"];
    remoteMedia.width = [jsonMedia numberForKey:@"width"];
    remoteMedia.exif = [jsonMedia dictionaryForKey:@"exif"];
    remoteMedia.remoteThumbnailURL = [jsonMedia stringForKeyPath:@"thumbnails.fmt_std"];
    remoteMedia.videopressGUID = [jsonMedia stringForKey:@"videopress_guid"];
    remoteMedia.length = [jsonMedia numberForKey:@"length"];
    return remoteMedia;
}


@end
