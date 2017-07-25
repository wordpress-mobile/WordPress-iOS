#import "MediaService+Legacy.h"
#import "AccountService.h"
#import "Blog.h"
#import "UIImage+Resize.h"
#import <MobileCoreServices/MobileCoreServices.h>
@import WordPressShared;

@implementation MediaService (Legacy)

- (void)createMediaWith:(id<ExportableAsset>)asset
            forObjectID:(NSManagedObjectID *)objectID
              mediaName:(NSString *)mediaName
      thumbnailCallback:(void (^)(NSURL *thumbnailURL))thumbnailCallback
             completion:(void (^)(Media *media, NSError *error))completion
{
    AbstractPost *post = nil;
    Blog *blog = nil;
    NSError *error = nil;
    NSManagedObject *existingObject = [self.managedObjectContext existingObjectWithID:objectID error:&error];

    if ([existingObject isKindOfClass:[AbstractPost class]]) {
        post = (AbstractPost *)existingObject;
        blog = post.blog;
    } else if ([existingObject isKindOfClass:[Blog class]]) {
        blog = (Blog *)existingObject;
    }

    if (!post && !blog) {
        if (completion) {
            completion(nil, error);
        }
        return;
    }

    MediaType mediaType = [asset assetMediaType];
    NSString *assetUTI = [asset originalUTI];
    NSString *extension = [self extensionForUTI:assetUTI];
    if (mediaType == MediaTypeImage) {
        NSSet *allowedFileTypes = blog.allowedFileTypes;
        if (![allowedFileTypes containsObject:extension]) {
            assetUTI = (__bridge NSString *)kUTTypeJPEG;
            extension = [self extensionForUTI:assetUTI];
        }
    } else if (mediaType == MediaTypeVideo) {
        if (![blog isHostedAtWPcom]) {
            assetUTI = (__bridge NSString *)kUTTypeMPEG4;
            extension = [self extensionForUTI:assetUTI];
        }
    }

    MediaSettings *mediaSettings = [MediaSettings new];
    BOOL stripGeoLocation = mediaSettings.removeLocationSetting;

    NSInteger maxImageSize = [mediaSettings imageSizeForUpload];
    CGSize maximumResolution = CGSizeMake(maxImageSize, maxImageSize);

    void(^trackResizedPhotoError)() = nil;
    if (mediaType == MediaTypeImage && maxImageSize > 0) {
        // Only tracking resized photo if the user selected a max size that's not the -1 value for "Original"
        NSDictionary *properties = @{@"resize_width": @(maxImageSize)};
        [WPAppAnalytics track:WPAnalyticsStatEditorResizedPhoto withProperties:properties withBlog:blog];
        trackResizedPhotoError = ^() {
            [self.managedObjectContext performBlock:^{
                [WPAppAnalytics track:WPAnalyticsStatEditorResizedPhotoError withProperties:properties withBlog:blog];
            }];
        };
    }

    error = nil;
    NSURL *mediaURL = [[MediaFileManager defaultManager] makeLocalMediaURLWithFilename:mediaName
                                                                         fileExtension:extension
                                                                                 error:&error];
    if (error) {
        if (completion) {
            completion(nil, error);
        }
        return;
    }
    error = nil;
    MediaFileManager *cacheFileManager = [MediaFileManager cacheManager];
    NSURL *mediaThumbnailURL = [cacheFileManager makeLocalMediaURLWithFilename:[cacheFileManager mediaFilenameAppendingThumbnail:[mediaURL lastPathComponent]]
                                                                 fileExtension:[self extensionForUTI:[asset defaultThumbnailUTI]]
                                                                         error:&error];
    if (error) {
        if (completion) {
            completion(nil, error);
        }
        return;
    }

    CGFloat imageMaxDimension = MAX([UIScreen mainScreen].nativeBounds.size.width, [UIScreen mainScreen].nativeBounds.size.height);
    CGSize thumbnailSize = CGSizeMake(imageMaxDimension, imageMaxDimension);

    [[self.class queueForResizeMediaOperations] addOperationWithBlock:^{
        [asset exportThumbnailToURL:mediaThumbnailURL
                         targetSize:thumbnailSize
                        synchronous:YES
                     successHandler:^(CGSize thumbnailSize) {
                         if (thumbnailCallback) {
                             thumbnailCallback(mediaThumbnailURL);
                         }
                         if ([assetUTI isEqual:(__bridge NSString *)kUTTypeGIF]) {
                             // export original gif
                             [asset exportOriginalImage:mediaURL successHandler:^(CGSize resultingSize) {
                                 [self createMediaForObjectID:objectID
                                                     mediaURL:mediaURL
                                            mediaThumbnailURL:mediaThumbnailURL
                                                    mediaType:mediaType
                                                    mediaSize:resultingSize
                                                        asset:asset
                                                   completion:completion];
                             } errorHandler:^(NSError * _Nonnull error) {
                                 if (completion){
                                     completion(nil, error);
                                 }
                             }];
                         } else {
                             [asset exportToURL:mediaURL
                                      targetUTI:assetUTI
                              maximumResolution:maximumResolution
                               stripGeoLocation:stripGeoLocation
                                    synchronous:true
                                 successHandler:^(CGSize resultingSize) {
                                     [self createMediaForObjectID:objectID
                                                         mediaURL:mediaURL
                                                mediaThumbnailURL:mediaThumbnailURL
                                                        mediaType:mediaType
                                                        mediaSize:resultingSize
                                                            asset:asset
                                                       completion:completion];
                                 } errorHandler:^(NSError *error) {
                                     if (completion){
                                         completion(nil, error);
                                     }
                                     if (trackResizedPhotoError) {
                                         trackResizedPhotoError();
                                     }
                                 }];
                         }
                     }
                       errorHandler:^(NSError *error) {
                           if (completion){
                               completion(nil, error);
                           }
                           if (trackResizedPhotoError) {
                               trackResizedPhotoError();
                           }
                       }];
    }];
}

- (void) createMediaForObjectID:(NSManagedObjectID *)objectID
                       mediaURL:(NSURL *)mediaURL
              mediaThumbnailURL:(NSURL *)mediaThumbnailURL
                      mediaType:(MediaType)mediaType
                      mediaSize:(CGSize)mediaSize
                          asset:(id <ExportableAsset>)asset
                     completion:(void (^)(Media *media, NSError *error))completion
{
    [self.managedObjectContext performBlock:^{
        Media *media = nil;
        NSManagedObject *object = [self.managedObjectContext objectWithID:objectID];

        if ([object isKindOfClass:[AbstractPost class]]) {
            AbstractPost *post = (AbstractPost *)object;
            media = [Media makeMediaWithPost:post];
            media.postID = post.postID;
        } else if ([object isKindOfClass:[Blog class]]) {
            Blog *blog = (Blog *)object;
            media = [Media makeMediaWithBlog:blog];
            media.remoteStatusNumber = @(MediaRemoteStatusLocal);
        }

        if (media) {
            [self configureNewMedia:media
                       withMediaURL:mediaURL
                  mediaThumbnailURL:mediaThumbnailURL
                          mediaType:mediaType
                          mediaSize:mediaSize
                              asset:asset];
        }

        [[ContextManager sharedInstance] saveContext:self.managedObjectContext withCompletionBlock:^{
            if (completion) {
                completion(media, nil);
            }
        }];
    }];
}

- (void)configureNewMedia:(Media *)media
             withMediaURL:(NSURL *)mediaURL
        mediaThumbnailURL:(NSURL *)mediaThumbnailURL
                mediaType:(MediaType)mediaType
                mediaSize:(CGSize)mediaSize
                    asset:(id <ExportableAsset>)asset
{
    media.filename = [mediaURL lastPathComponent];
    media.absoluteLocalURL = mediaURL;
    media.absoluteThumbnailLocalURL = mediaThumbnailURL;
    NSNumber * fileSize;
    if ([mediaURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:nil]) {
        media.filesize = @([fileSize longLongValue] / 1024);
    } else {
        media.filesize = 0;
    }
    media.width = @(mediaSize.width);
    media.height = @(mediaSize.height);
    media.mediaType = mediaType;
    if (mediaType == WPMediaTypeVideo && [asset isKindOfClass:[PHAsset class]]) {
        PHAsset *originalAsset = (PHAsset *)asset;
        media.length = @(originalAsset.duration);
    }
}

- (void)imageForMedia:(Media *)mediaInRandomContext
                 size:(CGSize)requestSize
              success:(void (^)(UIImage *image))success
              failure:(void (^)(NSError *error))failure
{
    NSManagedObjectID *mediaID = [mediaInRandomContext objectID];
    [self.managedObjectContext performBlock:^{
        Media *media = (Media *)[self.managedObjectContext objectWithID: mediaID];
        BOOL isPrivate = media.blog.isPrivate;

        // search if there is a local copy of the file already
        NSURL *fileURL;
        CGSize mediaOriginalSize = CGSizeMake([media.width floatValue], [media.height floatValue]);
        CGSize size = requestSize;
        if (CGSizeEqualToSize(requestSize, CGSizeZero)) {
            size = mediaOriginalSize;
        }
        CGSize availableSize = CGSizeZero;
        if (media.mediaType == MediaTypeImage) {
            fileURL = media.absoluteThumbnailLocalURL;
            availableSize = [[MediaFileManager cacheManager] imageSizeForMediaAtFileURL:fileURL];
            if (size.height > availableSize.height && size.width > availableSize.width) {
                fileURL = media.absoluteLocalURL;
                availableSize = [[MediaFileManager cacheManager] imageSizeForMediaAtFileURL:fileURL];
            }
        } else if (media.mediaType == MediaTypeVideo) {
            fileURL = media.absoluteThumbnailLocalURL;
            availableSize = [[MediaFileManager cacheManager] imageSizeForMediaAtFileURL:fileURL];
        }

        // check if the available local image is equal or larger than the requested size
        if (availableSize.height >= size.height && availableSize.width >= size.width) {
            [[[self class] queueForResizeMediaOperations] addOperationWithBlock:^{
                UIImage *image = [UIImage imageWithContentsOfFile:fileURL.path];
                if (success) {
                    if (!CGSizeEqualToSize(image.size, size)){
                        image = [image resizedImage:size interpolationQuality:kCGInterpolationMedium];
                    }
                    success(image);
                }
            }];
            return;
        }

        // No Image available so let's download it
        NSURL *remoteURL = nil;
        BOOL mediaIsVideo = media.mediaType == MediaTypeVideo;
        if (mediaIsVideo) {
            remoteURL = [NSURL URLWithString:media.remoteThumbnailURL];
        } else if (media.mediaType == MediaTypeImage) {
            NSString *remote = media.remoteURL;
            remoteURL = [NSURL URLWithString:remote];
            if (!media.blog.isPrivate) {
                remoteURL = [PhotonImageURLHelper photonURLWithSize:size forImageURL:remoteURL];
            } else {
                remoteURL = [WPImageURLHelper imageURLWithSize:size forImageURL:remoteURL];
            }

        }
        if (!remoteURL) {
            if (failure) {
                failure(nil);
            }
            return;
        }
        WPImageSource *imageSource = [WPImageSource sharedSource];
        void (^successBlock)(UIImage *) = ^(UIImage *image) {
            // Check the media hasn't been deleted whilst we were loading.
            if (!media || media.isDeleted) {
                if (success) {
                    success([UIImage new]);
                }
                return;
            }

            [self.managedObjectContext performBlock:^{
                NSError *error = nil;
                MediaFileManager *mediaFileManager = [MediaFileManager cacheManager];
                NSURL *fileURL = [mediaFileManager makeLocalMediaURLWithFilename:[mediaFileManager mediaFilenameAppendingThumbnail:media.filename]
                                                                   fileExtension:[self extensionForUTI:(__bridge NSString*)kUTTypeJPEG]
                                                                           error:&error];
                if (error) {
                    if (failure) {
                        failure(error);
                    }
                    return;
                }
                if (CGSizeEqualToSize(size, mediaOriginalSize) && !mediaIsVideo) {
                    media.absoluteLocalURL = fileURL;
                } else {
                    media.absoluteThumbnailLocalURL = fileURL;
                }
                [self.managedObjectContext save:nil];
                [[[self class] queueForResizeMediaOperations] addOperationWithBlock:^{
                    [image writeToURL:fileURL type:(__bridge NSString*)kUTTypeJPEG compressionQuality:0.9 metadata:nil error:nil];
                    if (success) {
                        success(image);
                    }
                }];
            }];
        };

        if (isPrivate) {
            AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:self.managedObjectContext];
            NSString *authToken = [[accountService defaultWordPressComAccount] authToken];
            [imageSource downloadImageForURL:remoteURL
                                   authToken:authToken
                                 withSuccess:successBlock
                                     failure:failure];
        } else {
            [imageSource downloadImageForURL:remoteURL
                                 withSuccess:successBlock
                                     failure:failure];
        }
    }];
}

- (NSString *)extensionForUTI:(NSString *)UTI {
    return (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassFilenameExtension);
}

+ (NSOperationQueue *)queueForResizeMediaOperations {
    static NSOperationQueue * _queueForResizeMediaOperations = nil;
    static dispatch_once_t _onceToken;
    dispatch_once(&_onceToken, ^{
        _queueForResizeMediaOperations = [[NSOperationQueue alloc] init];
        _queueForResizeMediaOperations.name = @"MediaService-ResizeMediaOperation";
        _queueForResizeMediaOperations.maxConcurrentOperationCount = 1;
    });

    return _queueForResizeMediaOperations;
}

@end
