#import "Media+WPMediaAsset.h"
#import "MediaService.h"
#import "Blog.h"
#import "ContextManager.h"
#import "WordPress-Swift.h"

@implementation Media(WPMediaAsset)

- (WPMediaRequestID)imageWithSize:(CGSize)size completionHandler:(WPMediaImageBlock)completionHandler
{
    [MediaThumbnailCoordinator.shared thumbnailFor:self with:size onCompletion:^(UIImage *image, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                if (completionHandler) {
                    completionHandler(nil, error);
                }
                return;
            }
            if (completionHandler) {
                completionHandler(image, nil);
            }
        });
    }];

    return [self.mediaID intValue];
}

- (WPMediaRequestID)videoAssetWithCompletionHandler:(WPMediaAssetBlock)completionHandler
{
    if (!completionHandler) {
        return 0;
    }

    // Check if asset being used is a video, if not this method fails
    if (!(self.assetType == WPMediaTypeVideo || self.assetType == WPMediaTypeAudio)) {
        NSString *errorMessage = NSLocalizedString(@"Selected media is not a video.", @"Error message when user tries to preview an image media like a video");
        completionHandler(nil, [self errorWithMessage:errorMessage]);
        return 0;
    }

    NSURL *url = nil;

    if ([self.absoluteLocalURL checkResourceIsReachableAndReturnError:nil] && [self.absoluteLocalURL isVideo]) {
        url = self.absoluteLocalURL;
    }

    if (!url && self.videopressGUID.length > 0 ){
        NSManagedObjectContext *mainContext = [[ContextManager sharedInstance] mainContext];
        MediaService *mediaService = [[MediaService alloc] initWithManagedObjectContext:mainContext];
        [mediaService getMediaURLFromVideoPressID:self.videopressGUID inBlog:self.blog success:^(NSString *videoURL, NSString *posterURL) {
            // Let see if can create an asset with this url
            AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL URLWithString:videoURL]];
            if (!asset) {
                NSString *errorMessage = NSLocalizedString(@"Selected media is unavailable.", @"Error message when user tries a no longer existent video media object.");
                completionHandler(nil, [self errorWithMessage:errorMessage]);
                return;
            }

            completionHandler(asset, nil);
        } failure:^(NSError *error) {
            completionHandler(nil, error);
        }];
        return 0;
    }
    // Do we have a local url, or remote url to use for the video
    if (!url && self.remoteURL) {
        url = [NSURL URLWithString:self.remoteURL];
    }

    if (!url) {
        NSString *errorMessage = NSLocalizedString(@"Selected media is unavailable.", @"Error message when user tries a no longer existent video media object.");
        completionHandler(nil, [self errorWithMessage:errorMessage]);
        return 0;
    }

    // Let see if can create an asset with this url
    AVURLAsset *asset = [AVURLAsset assetWithURL:url];
    if (!asset) {
        NSString *errorMessage = NSLocalizedString(@"Selected media is unavailable.", @"Error message when user tries a no longer existent video media object.");
        completionHandler(nil, [self errorWithMessage:errorMessage]);
        return 0;
    }

    completionHandler(asset, nil);
    return [self.mediaID intValue];
}

- (NSError *)errorWithMessage:(NSString *)errorMessage {
    return [NSError errorWithDomain:WPMediaPickerErrorDomain
                               code:WPMediaPickerErrorCodeVideoURLNotAvailable
                           userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
}

- (CGSize)pixelSize
{
    return CGSizeMake([self.width floatValue], [self.height floatValue]);
}

- (void)cancelImageRequest:(WPMediaRequestID)requestID
{

}

- (WPMediaType)assetType
{
    if (self.mediaType == MediaTypeImage) {
        return WPMediaTypeImage;
    } else if (self.mediaType == MediaTypeVideo) {
        return WPMediaTypeVideo;
    } else if (self.mediaType == MediaTypeAudio) {
        return WPMediaTypeAudio;
    } else {
        return WPMediaTypeOther;
    }
}

- (NSTimeInterval)duration
{
    if (!(self.mediaType == MediaTypeVideo || self.mediaType == MediaTypeAudio)) {
        return 0;
    }
    if (self.length != nil && [self.length doubleValue] > 0) {
        return [self.length doubleValue];
    }

    NSURL *absoluteLocalURL = self.absoluteLocalURL;
    if (absoluteLocalURL == nil || ![[NSFileManager defaultManager] fileExistsAtPath:absoluteLocalURL.path isDirectory:nil]) {
        return 0;
    }
    AVURLAsset *sourceAsset = [AVURLAsset URLAssetWithURL:absoluteLocalURL options:nil];
    CMTime duration = sourceAsset.duration;

    return CMTimeGetSeconds(duration);
}

- (NSDate *)date
{
    return self.creationDate;
}

- (id)baseAsset
{
    return self;
}

- (NSString *)identifier
{
    return [[self.objectID URIRepresentation] absoluteString];
}

- (NSString *)UTTypeIdentifier
{
    NSString *extension = [self fileExtension];
    if (!extension.length) {
        return nil;
    }
    return (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
}

@end
