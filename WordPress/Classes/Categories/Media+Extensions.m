#import "Media+Extensions.h"
#import "MediaService.h"
#import "Blog.h"
#import "CoreDataStack.h"
#import "WordPress-Swift.h"

@implementation Media (Extensions)

- (NSError *)errorWithMessage:(NSString *)errorMessage {
    return [NSError errorWithDomain:WPMediaPickerErrorDomain
                               code:WPMediaPickerErrorCodeVideoURLNotAvailable
                           userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
}

- (void)videoAssetWithCompletionHandler:(void (^ _Nonnull)(AVAsset * _Nullable asset, NSError * _Nullable error))completionHandler {
    if (!completionHandler) {
        return;
    }

    // Check if asset being used is a video, if not this method fails
    if (!(self.mediaType == MediaTypeVideo || self.mediaType == MediaTypeAudio)) {
        NSString *errorMessage = NSLocalizedString(@"Selected media is not a video.", @"Error message when user tries to preview an image media like a video");
        completionHandler(nil, [self errorWithMessage:errorMessage]);
        return;
    }

    NSURL *url = nil;

    if ([self.absoluteLocalURL checkResourceIsReachableAndReturnError:nil] && [self.absoluteLocalURL isVideo]) {
        url = self.absoluteLocalURL;
    }

    if (!url && self.videopressGUID.length > 0 ){
        id<MediaServiceRemote> mediaServiceRemote = [[MediaServiceRemoteFactory new] remoteForBlog:self.blog error:nil];
        [mediaServiceRemote getMetadataFromVideoPressID:self.videopressGUID isSitePrivate:self.blog.isPrivate success:^(RemoteVideoPressVideo *metadata) {
            // Let see if can create an asset with this url
            NSURL *originalURL = metadata.originalURL;
            if (!originalURL) {
                NSString *errorMessage = NSLocalizedString(@"Selected media is unavailable.", @"Error message when user tries a no longer existent video media object.");
                completionHandler(nil, [self errorWithMessage:errorMessage]);
                return;
            }
            NSURL *videoURL = [metadata getURLWithToken:originalURL] ?: originalURL;
            AVURLAsset *asset = [AVURLAsset assetWithURL:videoURL];
            if (!asset) {
                NSString *errorMessage = NSLocalizedString(@"Selected media is unavailable.", @"Error message when user tries a no longer existent video media object.");
                completionHandler(nil, [self errorWithMessage:errorMessage]);
                return;
            }

            completionHandler(asset, nil);
        } failure:^(NSError *error) {
            completionHandler(nil, error);
        }];
        return;
    }
    // Do we have a local url, or remote url to use for the video
    if (!url && self.remoteURL) {
        url = [NSURL URLWithString:self.remoteURL];
    }

    if (!url) {
        NSString *errorMessage = NSLocalizedString(@"Selected media is unavailable.", @"Error message when user tries a no longer existent video media object.");
        completionHandler(nil, [self errorWithMessage:errorMessage]);
        return;
    }

    // Let see if can create an asset with this url
    AVURLAsset *asset = [AVURLAsset assetWithURL:url];
    if (!asset) {
        NSString *errorMessage = NSLocalizedString(@"Selected media is unavailable.", @"Error message when user tries a no longer existent video media object.");
        completionHandler(nil, [self errorWithMessage:errorMessage]);
        return;
    }

    completionHandler(asset, nil);
}

- (CGSize)pixelSize
{
    return CGSizeMake([self.width floatValue], [self.height floatValue]);
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

@end
