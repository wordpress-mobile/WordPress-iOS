#import "WPMediaUploader.h"
#import "Media.h"

// Notifications
extern NSString *const MediaShouldInsertBelowNotification;

NSString *const WPMediaUploaderUploadOperation = @"upload_operation";

@interface WPMediaUploader() {
    NSMapTable *_mediaUploads;
    NSUInteger _numberOfImagesToUpload;
    NSUInteger _numberOfImagesProcessed;
}

@property BOOL isCurrentlyUploading;

@end

@implementation WPMediaUploader

- (id)init
{
    self = [super init];
    if (self) {
        _mediaUploads = [NSMapTable strongToStrongObjectsMapTable];
    }
    return self;
}

- (void)uploadMediaObjects:(NSArray *)mediaObjects
{
    if ([mediaObjects count] == 0)
        return;
    
    _numberOfImagesToUpload += [mediaObjects count];
    
    // wait for a media upload to finish so that images appear in order of selection
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        for (Media *media in mediaObjects) {
            
            [self uploadMedia:media];
            self.isUploadingMedia = YES;
            
            while (self.isUploadingMedia) {
                [NSThread sleepForTimeInterval:0.5];
            }
        }
    });
}

- (void)uploadMedia:(Media *)media
{
    [self uploadMedia:media withSuccess:^{
        if ([media isDeleted]) {
            DDLogWarn(@"Media uploader found deleted media while uploading (%@)", media);
            return;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:MediaShouldInsertBelowNotification object:media];
        [media save];
    } failure:^(NSError *error){
        if (error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled) {
            DDLogWarn(@"Media uploader failed with cancelled upload: %@", error.localizedDescription);
            return;
        }
        
        [WPError showAlertWithTitle:NSLocalizedString(@"Upload failed", nil) message:error.localizedDescription];
    }];
}

- (void)cancelAllUploads
{
    for (Media *media in _mediaUploads) {
        NSDictionary *uploadInformation = [_mediaUploads objectForKey:media];
        AFHTTPRequestOperation *operation = [uploadInformation objectForKey:WPMediaUploaderUploadOperation];
        [operation cancel];
    }
    [_mediaUploads removeAllObjects];
    self.isUploadingMedia = NO;
}

- (void)uploadMedia:(Media *)media withSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    NSString *mimeType = (media.mediaType == MediaTypeVideo) ? @"video/mp4" : @"image/jpeg";
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:
                            mimeType, @"type",
                            media.filename, @"name",
                            [NSInputStream inputStreamWithFileAtPath:media.localURL], @"bits",
                            nil];
    NSArray *parameters = [media.blog getXMLRPCArgsWithExtra:object];

    media.remoteStatus = MediaRemoteStatusProcessing;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^(void) {
        // Create the request asynchronously
        // TODO: use streaming to avoid processing on memory
        NSMutableURLRequest *request = [media.blog.api requestWithMethod:@"metaWeblog.newMediaObject" parameters:parameters];

        dispatch_async(dispatch_get_main_queue(), ^(void) {
            void (^failureBlock)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error) {
                if ([media isDeleted] || media.managedObjectContext == nil) {
                    return;
                }

                media.remoteStatus = MediaRemoteStatusFailed;
                [_mediaUploads removeObjectForKey:media];
                _numberOfImagesProcessed++;
                [self updateUploadProgress];
                if (failure) {
                    failure(error);
                    self.isUploadingMedia = NO;
                }
            };
            AFHTTPRequestOperation *operation = [media.blog.api HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
                if ([media isDeleted] || media.managedObjectContext == nil)
                    return;

                NSDictionary *response = (NSDictionary *)responseObject;

                if (![response isKindOfClass:[NSDictionary class]]) {
                    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"The server returned an empty response. This usually means you need to increase the memory limit for your site.", @"")}];
                    failureBlock(operation, error);
                    return;
                }
                if([response objectForKey:@"videopress_shortcode"] != nil)
                    media.shortcode = [response objectForKey:@"videopress_shortcode"];

                if([response objectForKey:@"url"] != nil)
                    media.remoteURL = [response objectForKey:@"url"];
                
                if ([response objectForKey:@"id"] != nil) {
                    media.mediaID = [[response objectForKey:@"id"] numericValue];
                }

                media.remoteStatus = MediaRemoteStatusSync;
                [_mediaUploads removeObjectForKey:media];
                _numberOfImagesProcessed++;
                [self updateUploadProgress];
                if (success) {
                    success();
                    self.isUploadingMedia = NO;
                    
                }
            } failure:failureBlock];
            [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    if ([media isDeleted] || media.managedObjectContext == nil)
                        return;
                    media.progress = (float)totalBytesWritten / (float)totalBytesExpectedToWrite;
                });
            }];
            
            // Upload might have been canceled while processing
            if (media.remoteStatus == MediaRemoteStatusProcessing) {
                media.remoteStatus = MediaRemoteStatusPushing;
                [media.blog.api enqueueHTTPRequestOperation:operation];
                NSMutableDictionary *uploadInformation = [[NSMutableDictionary alloc] initWithDictionary:@{WPMediaUploaderUploadOperation: operation}];
                [_mediaUploads setObject:uploadInformation forKey:media];
            }
        });
    });
}

- (void)updateUploadProgress
{
    if (self.uploadProgressBlock) {
        self.uploadProgressBlock(_numberOfImagesProcessed, _numberOfImagesToUpload);
    }
    
    if (_numberOfImagesProcessed == _numberOfImagesToUpload && self.uploadsCompletedBlock) {
        self.isUploadingMedia = NO;
        self.uploadsCompletedBlock();
    }
}

@end
