#import "MediaService.h"
#import "AccountService.h"
#import "Media.h"
#import "WPAccount.h"
#import "ContextManager.h"
#import "MediaServiceRemoteXMLRPC.h"
#import "MediaServiceRemoteREST.h"
#import "Blog.h"
#import "RemoteMedia.h"
#import "WPImageSource.h"
#import "UIImage+Resize.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "WordPress-Swift.h"
#import "WPXMLRPCDecoder.h"
#import "PhotonImageURLHelper.h"

@implementation MediaService

- (void)createMediaWithURL:(NSURL *)url
           forPostObjectID:(NSManagedObjectID *)postObjectID
         thumbnailCallback:(void (^)(NSURL *thumbnailURL))thumbnailCallback
                completion:(void (^)(Media *media, NSError *error))completion
{

    NSString *mediaName = [[url pathComponents] lastObject];

    [self createMediaWith:url
          forPostObjectID:postObjectID
                mediaName:mediaName
        thumbnailCallback:thumbnailCallback
               completion:completion
     ];
}

- (void)createMediaWithImage:(UIImage *)image
                 withMediaID:(NSString *)mediaID
             forPostObjectID:(NSManagedObjectID *)postObjectID
           thumbnailCallback:(void (^)(NSURL *thumbnailURL))thumbnailCallback
                  completion:(void (^)(Media *media, NSError *error))completion
{
    [self createMediaWith:image
          forPostObjectID:postObjectID
                mediaName:mediaID
        thumbnailCallback:thumbnailCallback
               completion:completion
     ];
}

- (void)createMediaWithPHAsset:(PHAsset *)asset
               forPostObjectID:(NSManagedObjectID *)postObjectID
             thumbnailCallback:(void (^)(NSURL *thumbnailURL))thumbnailCallback
                    completion:(void (^)(Media *media, NSError *error))completion
{
    NSString *mediaName = [asset originalFilename];
    
    [self createMediaWith:asset
          forPostObjectID:postObjectID
                mediaName:mediaName
        thumbnailCallback:thumbnailCallback
               completion:completion
     ];
}

- (void)createMediaWith:(id<ExportableAsset>)asset
        forPostObjectID:(NSManagedObjectID *)postObjectID
              mediaName:(NSString *)mediaName
      thumbnailCallback:(void (^)(NSURL *thumbnailURL))thumbnailCallback
             completion:(void (^)(Media *media, NSError *error))completion
{
    NSError *error = nil;
    AbstractPost *post = (AbstractPost *)[self.managedObjectContext existingObjectWithID:postObjectID error:&error];
    if (!post) {
        if (completion) {
            completion(nil, error);
        }
        return;
    }
    
    MediaType mediaType = [asset assetMediaType];
    NSString *assetUTI = [asset originalUTI];
    NSString *extension = [self extensionForUTI:assetUTI];
    if (mediaType == MediaTypeImage) {
        NSSet *allowedFileTypes = post.blog.allowedFileTypes;
        if (![allowedFileTypes containsObject:extension]) {
            assetUTI = (__bridge NSString *)kUTTypeJPEG;
            extension = [self extensionForUTI:assetUTI];
        }
    } else if (mediaType == MediaTypeVideo) {
        if (![post.blog isHostedAtWPcom]) {
            assetUTI = (__bridge NSString *)kUTTypeQuickTimeMovie;
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
        [WPAppAnalytics track:WPAnalyticsStatEditorResizedPhoto withProperties:properties withBlog:post.blog];
        trackResizedPhotoError = ^() {
            [self.managedObjectContext performBlock:^{
                [WPAppAnalytics track:WPAnalyticsStatEditorResizedPhotoError withProperties:properties withBlog:post.blog];
            }];
        };
    }
    
    NSURL *mediaURL = [self urlForMediaWithFilename:mediaName andExtension:extension];
    NSURL *mediaThumbnailURL = [self urlForMediaWithFilename:[self pathForThumbnailOfFile:[mediaURL lastPathComponent]]
                                                andExtension:[self extensionForUTI:[asset defaultThumbnailUTI]]];
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
                                 [self createMediaForPost:postObjectID
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
                                     [self createMediaForPost:postObjectID
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

- (void) createMediaForPost:(NSManagedObjectID *)postObjectID
                   mediaURL:(NSURL *)mediaURL
          mediaThumbnailURL:(NSURL *)mediaThumbnailURL
                  mediaType:(MediaType)mediaType
                  mediaSize:(CGSize)mediaSize
                      asset:(id <ExportableAsset>)asset
                 completion:(void (^)(Media *media, NSError *error))completion
{
 
    [self.managedObjectContext performBlock:^{
        AbstractPost *post = (AbstractPost *)[self.managedObjectContext objectWithID:postObjectID];
        Media *media = [self newMediaForPost:post];
        media.postID = post.postID;
        media.filename = [mediaURL lastPathComponent];
        media.absoluteLocalURL = [mediaURL path];
        media.absoluteThumbnailLocalURL = [mediaThumbnailURL path];
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
        //make sure that we only return when object is properly created and saved
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext withCompletionBlock:^{
            if (completion) {
                completion(media, nil);
            }
        }];
    }];
}

- (void)uploadMedia:(Media *)media
           progress:(NSProgress **)progress
           success:(void (^)())success
           failure:(void (^)(NSError *error))failure
{
    id<MediaServiceRemote> remote = [self remoteForBlog:media.blog];
    RemoteMedia *remoteMedia = [self remoteMediaFromMedia:media];

    // Even though jpeg is a valid extension, use jpg instead for the widest possible
    // support.  Some third-party image related plugins prefer the .jpg extension.
    // See https://github.com/wordpress-mobile/WordPress-iOS/issues/4663
    remoteMedia.file = [remoteMedia.file stringByReplacingOccurrencesOfString:@".jpeg" withString:@".jpg"];

    media.remoteStatus = MediaRemoteStatusPushing;
    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    NSManagedObjectID *mediaObjectID = media.objectID;
    void (^successBlock)(RemoteMedia *media) = ^(RemoteMedia *media) {
        [self.managedObjectContext performBlock:^{
            NSError * error = nil;
            Media *mediaInContext = (Media *)[self.managedObjectContext existingObjectWithID:mediaObjectID error:&error];
            if (!mediaInContext){
                DDLogError(@"Error retrieving media object: %@", error);
                if (failure){
                    failure(error);
                }
                return;
            }
            
            [self updateMedia:mediaInContext withRemoteMedia:media];
            mediaInContext.remoteStatus = MediaRemoteStatusSync;
            [[ContextManager sharedInstance] saveContext:self.managedObjectContext withCompletionBlock:^{
                if (success) {
                    success();
                }
            }];
        }];
    };
    void (^failureBlock)(NSError *error) = ^(NSError *error) {
        [self.managedObjectContext performBlock:^{
            Media *mediaInContext = (Media *)[self.managedObjectContext existingObjectWithID:mediaObjectID error:nil];
            if (mediaInContext) {
                mediaInContext.remoteStatus = MediaRemoteStatusFailed;
                [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
            }
            if (failure) {
                failure([self customMediaUploadError:error remote:remote]);
            }
        }];
    };
    
    [remote createMedia:remoteMedia
               progress:progress
                success:successBlock
                failure:failureBlock];
}

- (void)updateMedia:(Media *)media
            success:(void (^)())success
            failure:(void (^)(NSError *error))failure
{
    id<MediaServiceRemote> remote = [self remoteForBlog:media.blog];
    RemoteMedia *remoteMedia = [self remoteMediaFromMedia:media];
    NSManagedObjectID *mediaObjectID = media.objectID;
    void (^successBlock)(RemoteMedia *media) = ^(RemoteMedia *media) {
        [self.managedObjectContext performBlock:^{
            NSError * error = nil;
            Media *mediaInContext = (Media *)[self.managedObjectContext existingObjectWithID:mediaObjectID error:&error];
            if (!mediaInContext){
                DDLogError(@"Error updating media object: %@", error);
                if (failure){
                    failure(error);
                }
                return;
            }

            [self updateMedia:mediaInContext withRemoteMedia:media];
            [[ContextManager sharedInstance] saveContext:self.managedObjectContext withCompletionBlock:^{
                if (success) {
                    success();
                }
            }];
        }];
    };
    void (^failureBlock)(NSError *error) = ^(NSError *error) {
        [self.managedObjectContext performBlock:^{
            Media *mediaInContext = (Media *)[self.managedObjectContext existingObjectWithID:mediaObjectID error:nil];
            if (mediaInContext) {
                [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
            }
            if (failure) {
                failure([self customMediaUploadError:error remote:remote]);
            }
        }];
    };

    [remote updateMedia:remoteMedia
                success:successBlock
                failure:failureBlock];
}

- (void)updateMultipleMedia:(NSArray<Media *> *)mediaObjects
             overallSuccess:(void (^)())overallSuccess
                    failure:(void (^)(NSError *error))failure
{
    if (mediaObjects.count == 0) {
        if (overallSuccess) {
            overallSuccess();
        }
        return;
    }

    NSNumber *totalOperations = @(mediaObjects.count);
    __block NSUInteger completedOperations = 0;
    __block NSUInteger failedOperations = 0;

    void (^individualOperationCompletion)(BOOL success) = ^(BOOL success) {
        @synchronized (totalOperations) {
            completedOperations += 1;
            failedOperations += success ? 0 : 1;

            if (completedOperations >= totalOperations.unsignedIntegerValue) {
                if (overallSuccess && failedOperations != totalOperations.unsignedIntegerValue) {
                    overallSuccess();
                } else if (failure && failedOperations == totalOperations.unsignedIntegerValue) {
                    NSError *error = [NSError errorWithDomain:WordPressComRestApiErrorDomain
                                                         code:WordPressComRestApiErrorUnknown
                                                     userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"An error occurred when attempting to attach uploaded media to the post.", @"Error recorded when all of the media associated with a post fail to be attached to the post on the server.")}];
                    failure(error);
                }
            }
        }
    };

    for (Media *media in mediaObjects) {
        // This effectively ignores any errors presented
        [self updateMedia:media success:^{
            individualOperationCompletion(true);
        } failure:^(NSError *error) {
            individualOperationCompletion(false);
        }];
    }

}

- (NSError *)customMediaUploadError:(NSError *)error remote:(id <MediaServiceRemote>)remote {
    NSString *customErrorMessage = nil;
    if ([remote isKindOfClass:[MediaServiceRemoteXMLRPC class]]) {
        // For self-hosted sites we should generally pass on the raw system/network error message.
        // Which should help debug issues with a self-hosted site.
        if ([error.domain isEqualToString:WPXMLRPCFaultErrorDomain]) {
            switch (error.code) {
                case 500:{
                    customErrorMessage = NSLocalizedString(@"Your site does not support this media file format.", @"Message to show to user when media upload failed because server doesn't support media type");
                } break;
                case 401:{
                    customErrorMessage = NSLocalizedString(@"Your site is out of storage space for media uploads.", @"Message to show to user when media upload failed because user doesn't have enough space on quota/disk");
                } break;
            }
        }
    } else if ([remote isKindOfClass:[MediaServiceRemoteREST class]]) {
        // For WPCom/Jetpack sites and NSURLErrors we should use a more general error message to encourage a user to try again,
        // rather than raw NSURLError messaging.
        if ([error.domain isEqualToString:NSURLErrorDomain]) {
            switch (error.code) {
                case NSURLErrorUnknown:
                    // Unknown error, encourage the user to try again
                    // Note: if support requests show up with this error message we can rule out known NSURLError codes
                    customErrorMessage = NSLocalizedString(@"Media upload failed, an unknown error occurred, please try again.", @"Error message shown when a media upload fails for unknown reason and the user should try again.");
                    break;
                case NSURLErrorNetworkConnectionLost:
                case NSURLErrorNotConnectedToInternet:
                    // Clear lack of device internet connection, notify the user
                    customErrorMessage = NSLocalizedString(@"Media upload failed, internet connection appears to be offline.", @"Error message shown when a media upload fails because the user isn't connected to the internet.");
                    break;
                default:
                    // Default NSURL error messaging, probably server-side, encourage user to try again
                    customErrorMessage = NSLocalizedString(@"Media upload failed, please try again in a moment.", @"Error message shown when a media upload fails for a general network issue and the user should try again in a moment.");
                    break;
            }
        }
    }
    if (customErrorMessage) {
        NSMutableDictionary *userInfo = [error.userInfo mutableCopy];
        userInfo[NSLocalizedDescriptionKey] = customErrorMessage;
        error = [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:userInfo];
    }
    return error;
}

- (void) getMediaWithID:(NSNumber *) mediaID inBlog:(Blog *) blog
            withSuccess:(void (^)(Media *media))success
                failure:(void (^)(NSError *error))failure
{
    id<MediaServiceRemote> remote = [self remoteForBlog:blog];
    NSManagedObjectID *blogID = blog.objectID;
    
    [remote getMediaWithID:mediaID success:^(RemoteMedia *remoteMedia) {
       [self.managedObjectContext performBlock:^{
           Blog *blog = (Blog *)[self.managedObjectContext existingObjectWithID:blogID error:nil];
           if (!blog) {
               return;
           }
           Media *media = [self findMediaWithID:remoteMedia.mediaID inBlog:blog];
           if (!media) {
               media = [self newMediaForBlog:blog];
           }
           [self updateMedia:media withRemoteMedia:remoteMedia];
           if (success){
               success(media);
           }
           [[ContextManager sharedInstance] saveDerivedContext:self.managedObjectContext];
       }];
    } failure:^(NSError *error) {
        if (failure) {
            [self.managedObjectContext performBlock:^{
                failure(error);
            }];
        }

    }];
}

- (Media *)findMediaWithID:(NSNumber *)mediaID inBlog:(Blog *)blog
{
    NSSet *media = [blog.media filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"mediaID = %@", mediaID]];
    return [media anyObject];
}

- (void)getMediaURLFromVideoPressID:(NSString *)videoPressID
                             inBlog:(Blog *)blog
                            success:(void (^)(NSString *videoURL, NSString *posterURL))success
                            failure:(void (^)(NSError *error))failure
{
    NSString *entityName = NSStringFromClass([Media class]);
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    request.predicate = [NSPredicate predicateWithFormat:@"videopressGUID = %@", videoPressID];
    NSError *error = nil;
    Media *media = [[self.managedObjectContext executeFetchRequest:request error:&error] firstObject];
    if (media) {
        NSString  *posterURL = media.absoluteThumbnailLocalURL;
        if (!posterURL) {
            posterURL = media.remoteThumbnailURL;
        }
        if (success) {
            success(media.remoteURL, posterURL);
        }
    } else {
        if (failure) {
            failure(error);
        }
    }
}

- (void)syncMediaLibraryForBlog:(Blog *)blog
                        success:(void (^)())success
                        failure:(void (^)(NSError *error))failure
{
    id<MediaServiceRemote> remote = [self remoteForBlog:blog];
    NSManagedObjectID *blogObjectID = [blog objectID];
    [remote getMediaLibraryWithSuccess:^(NSArray *media) {
                               [self.managedObjectContext performBlock:^{
                                   Blog *blogInContext = (Blog *)[self.managedObjectContext objectWithID:blogObjectID];
                                   [self mergeMedia:media forBlog:blogInContext completionHandler:success];
                               }];
                           }
                           failure:^(NSError *error) {
                               if (failure) {
                                   [self.managedObjectContext performBlock:^{
                                       failure(error);
                                   }];
                               }
                           }];
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

- (CGSize)sizeOfMediaFileAtPath:(NSString *)pathForFile {
    if (pathForFile == nil || ![[NSFileManager defaultManager] fileExistsAtPath:pathForFile isDirectory:nil]) {
        return CGSizeZero;
    }
    NSURL *imageFileURL = [NSURL fileURLWithPath:pathForFile];
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((CFURLRef)imageFileURL, NULL);
    if (imageSource == NULL) {
        // Error loading image
        return CGSizeZero;
    }

    CGFloat width = 0.0f, height = 0.0f;
    CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);

    CFRelease(imageSource);

    if (imageProperties == NULL) {
        return CGSizeZero;
    }

    CFNumberRef widthNum  = CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelWidth);
    if (widthNum != NULL) {
        CFNumberGetValue(widthNum, kCFNumberCGFloatType, &width);
    }

    CFNumberRef heightNum = CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelHeight);
    if (heightNum != NULL) {
        CFNumberGetValue(heightNum, kCFNumberCGFloatType, &height);
    }

    // Check orientation and flip size if required
    CFNumberRef orientationNum = CFDictionaryGetValue(imageProperties, kCGImagePropertyOrientation);
    if (orientationNum != NULL) {
        int orientation;
        CFNumberGetValue(orientationNum, kCFNumberIntType, &orientation);
        if (orientation > 4) {
            CGFloat temp = width;
            width = height;
            height = temp;
        }
    }
    
    CFRelease(imageProperties);

    return CGSizeMake(width, height);
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
        NSString *pathForFile;
        CGSize mediaOriginalSize = CGSizeMake([media.width floatValue], [media.height floatValue]);
        CGSize size = requestSize;
        if (CGSizeEqualToSize(requestSize, CGSizeZero)) {
            size = mediaOriginalSize;
        }
        CGSize availableSize = CGSizeZero;
        if (media.mediaType == MediaTypeImage) {
            pathForFile = media.absoluteThumbnailLocalURL;
            availableSize = [self sizeOfMediaFileAtPath:pathForFile];
            if (size.height > availableSize.height && size.width > availableSize.width) {
                pathForFile = media.absoluteLocalURL;
                availableSize = [self sizeOfMediaFileAtPath:pathForFile];
            }
        } else if (media.mediaType == MediaTypeVideo) {
            pathForFile = media.absoluteThumbnailLocalURL;
            availableSize = [self sizeOfMediaFileAtPath:pathForFile];
        }

        // check if the available local image is equal or larger than the requested size
        if (availableSize.height >= size.height && availableSize.width >= size.width) {
            [[[self class] queueForResizeMediaOperations] addOperationWithBlock:^{
                UIImage *image = [UIImage imageWithContentsOfFile:pathForFile];
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
        if (media.mediaType == MediaTypeVideo) {
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
            [self.managedObjectContext performBlock:^{
                NSURL *fileURL = [self urlForMediaWithFilename:[self pathForThumbnailOfFile:media.filename]
                                                  andExtension:[self extensionForUTI:(__bridge NSString*)kUTTypeJPEG]];
                if (CGSizeEqualToSize(size, mediaOriginalSize)) {
                    media.absoluteLocalURL = [fileURL path];
                } else {
                    media.absoluteThumbnailLocalURL = [fileURL path];
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

- (NSInteger)getMediaLibraryCountForBlog:(Blog *)blog
                           forMediaTypes:(NSSet *)mediaTypes
{
    NSString *entityName = NSStringFromClass([Media class]);
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    request.predicate = [self predicateForMediaTypes:mediaTypes blog:blog];
    NSError *error;
    NSArray *mediaAssets = [self.managedObjectContext executeFetchRequest:request error:&error];
    return mediaAssets.count;
}

- (NSPredicate *)predicateForMediaTypes:(NSSet *)mediaTypes blog:(Blog *)blog
{
    NSMutableArray * filters = [NSMutableArray array];
    [mediaTypes enumerateObjectsUsingBlock:^(NSNumber *obj, BOOL *stop){
        MediaType filter = (MediaType)[obj intValue];
        NSString *filterString = [Media stringFromMediaType:filter];
        [filters addObject:[NSString stringWithFormat:@"mediaTypeString == \"%@\"", filterString]];
    }];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"blog == %@", blog];
    if (filters.count > 0) {
        NSString *mediaFilters = [filters componentsJoinedByString:@" || "];
        NSPredicate *mediaPredicate = [NSPredicate predicateWithFormat:mediaFilters];
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:
                     @[predicate, mediaPredicate]];
    }

    return predicate;
}

#pragma mark - Private

#pragma mark - Media Creation

- (Media *)newMedia
{
    Media *media = [NSEntityDescription insertNewObjectForEntityForName:@"Media" inManagedObjectContext:self.managedObjectContext];
    media.creationDate = [NSDate date];
    media.mediaID = @0;
    // We only support images for now, so let's set the default here
    media.mediaType = MediaTypeImage;
    return media;
}

- (Media *)newMediaForBlog:(Blog *)blog
{
    Media *media = [self newMedia];
    media.blog = blog;
    return media;
}

- (Media *)newMediaForPost:(AbstractPost *)post
{
    Media *media = [self newMediaForBlog:post.blog];
    [media addPostsObject:post];
    return media;
}

#pragma mark - Media helpers

- (NSString *)extensionForUTI:(NSString *)UTI {
    return (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassFilenameExtension);
}

static NSString * const MediaDirectory = @"Media";

+ (NSURL *)urlForMediaDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL * documentsURL = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
    NSURL * mediaURL = [documentsURL URLByAppendingPathComponent:MediaDirectory isDirectory:YES];
    NSError *error;
    if (![mediaURL checkResourceIsReachableAndReturnError:&error]) {
        if (![fileManager createDirectoryAtURL:mediaURL withIntermediateDirectories:YES attributes:nil error:&error]){
            DDLogError(@"%@", [error localizedDescription]);
            return nil;
        }
        [mediaURL setResourceValue:@(NO) forKey:NSURLIsExcludedFromBackupKey error:nil];
    }
    
    return mediaURL;
}

- (NSURL *)urlForMediaWithFilename:(NSString *)filename andExtension:(NSString *)extension
{
    NSURL *mediaDirectoryURL = [[self class] urlForMediaDirectory];
    NSString *basename = [[filename stringByDeletingPathExtension] lowercaseString];
    NSURL *resultURL = [mediaDirectoryURL URLByAppendingPathComponent:basename];
    resultURL = [resultURL URLByAppendingPathExtension:extension];
    NSUInteger index = 1;
    while ([resultURL checkResourceIsReachableAndReturnError:nil]) {
        NSString *alternativeFilename = [NSString stringWithFormat:@"%@-%d.%@", basename, index, extension];
        resultURL = [mediaDirectoryURL URLByAppendingPathComponent:alternativeFilename];
        index++;
    }
    return resultURL;
}

- (NSString *)pathForThumbnailOfFile:(NSString *)filename
{
    NSString *extension = [filename pathExtension];
    NSString *fileWithoutExtension = [filename stringByDeletingPathExtension];
    NSString *thumbnailPath = [fileWithoutExtension stringByAppendingString:@"-thumbnail"];
    thumbnailPath = [thumbnailPath stringByAppendingPathExtension:extension];
    return thumbnailPath;
}

- (NSString *)mimeTypeForFilename:(NSString *)filename
{
    if (!filename || ![filename pathExtension]) {
        return @"application/octet-stream";
    }
    // Get the UTI from the file's extension:
    CFStringRef pathExtension = (__bridge_retained CFStringRef)[filename pathExtension];
    CFStringRef type = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, NULL);
    CFRelease(pathExtension);

    // The UTI can be converted to a mime type:
    NSString *mimeType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass(type, kUTTagClassMIMEType);
    if (type != NULL) {
        CFRelease(type);
    }

    return mimeType;
}

- (id<MediaServiceRemote>)remoteForBlog:(Blog *)blog
{
    id <MediaServiceRemote> remote;
    if ([blog supports:BlogFeatureWPComRESTAPI]) {
        if (blog.wordPressComRestApi) {
            remote = [[MediaServiceRemoteREST alloc] initWithWordPressComRestApi:blog.wordPressComRestApi
                                                                          siteID:blog.dotComID];
        }
    } else if (blog.xmlrpcApi) {
        remote = [[MediaServiceRemoteXMLRPC alloc] initWithApi:blog.xmlrpcApi username:blog.username password:blog.password];
    }
    return remote;
}

- (void)mergeMedia:(NSArray *)media
           forBlog:(Blog *)blog
 completionHandler:(void (^)(void))completion
{
    NSParameterAssert(blog);
    NSParameterAssert(media);
    NSMutableSet *mediaToKeep = [NSMutableSet set];
    for (RemoteMedia *remote in media) {
        @autoreleasepool {
            Media *local = [self findMediaWithID:remote.mediaID inBlog:blog];
            if (!local) {
                local = [self newMediaForBlog:blog];
                local.remoteStatus = MediaRemoteStatusSync;
            }
            [self updateMedia:local withRemoteMedia:remote];
            [mediaToKeep addObject:local];
        }
    }
    NSMutableSet *mediaToDelete = [NSMutableSet setWithSet:blog.media];
    [mediaToDelete minusSet:mediaToKeep];
    for (Media *deleteMedia in mediaToDelete) {
        // only delete media that is server based
        if ([deleteMedia.mediaID intValue] > 0) {
            [self.managedObjectContext deleteObject:deleteMedia];
        }
    }
    NSError *error;
    if (![self.managedObjectContext save:&error]){
        DDLogError(@"Error saving context afer adding media %@", [error localizedDescription]);
    }
    if (completion) {
        completion();
    }
}

- (void)updateMedia:(Media *)media withRemoteMedia:(RemoteMedia *)remoteMedia
{
    media.mediaID =  remoteMedia.mediaID;
    media.remoteURL = [remoteMedia.url absoluteString];
    if (remoteMedia.date) {
        media.creationDate = remoteMedia.date;
    }
    media.filename = remoteMedia.file;
    [media mediaTypeFromUrl:[remoteMedia extension]];
    media.title = remoteMedia.title;
    media.caption = remoteMedia.caption;
    media.desc = remoteMedia.descriptionText;
    media.height = remoteMedia.height;
    media.width = remoteMedia.width;
    media.shortcode = remoteMedia.shortcode;
    media.videopressGUID = remoteMedia.videopressGUID;
    media.length = remoteMedia.length;
    media.remoteThumbnailURL = remoteMedia.remoteThumbnailURL;
    media.postID = remoteMedia.postID;
}

- (RemoteMedia *)remoteMediaFromMedia:(Media *)media
{
    RemoteMedia *remoteMedia = [[RemoteMedia alloc] init];
    remoteMedia.mediaID = media.mediaID;
    remoteMedia.url = [NSURL URLWithString:media.remoteURL];
    remoteMedia.date = media.creationDate;
    remoteMedia.file = media.filename;
    remoteMedia.extension = [media.filename pathExtension] ? :@"unknown";
    remoteMedia.title = media.title;
    remoteMedia.caption = media.caption;
    remoteMedia.descriptionText = media.desc;
    remoteMedia.height = media.height;
    remoteMedia.width = media.width;
    remoteMedia.localURL = media.absoluteLocalURL;
    remoteMedia.mimeType = [self mimeTypeForFilename:media.absoluteLocalURL];
	remoteMedia.videopressGUID = media.videopressGUID;
    remoteMedia.remoteThumbnailURL = media.remoteThumbnailURL;
    remoteMedia.postID = media.postID;
    return remoteMedia;
}

#pragma mark - Media cleanup

+ (void)cleanUnusedMediaFilesFromMediaCacheFolder
{
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));

    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    [context performBlock:^{

        // Fetch Media URL's and return them as Dictionary Results:
        // This way we'll avoid any CoreData Faulting Exception due to deletions performed on another context
        NSString *localUrlProperty = NSStringFromSelector(@selector(localURL));
        NSString *localThumbUrlProperty = NSStringFromSelector(@selector(localThumbnailURL));

        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        fetchRequest.entity = [NSEntityDescription entityForName:NSStringFromClass([Media class]) inManagedObjectContext:context];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"blog != NULL"];

        fetchRequest.propertiesToFetch = @[ localUrlProperty, localThumbUrlProperty ];
        fetchRequest.resultType = NSDictionaryResultType;

        NSError *error = nil;
        NSArray *mediaObjectsToKeep = [context executeFetchRequest:fetchRequest error:&error];

        if (error) {
            DDLogError(@"Error cleaning up tmp files: %@", error.localizedDescription);
            return;
        }

        // Get a references to media files linked in a post
        DDLogInfo(@"%i media items to check for cleanup", mediaObjectsToKeep.count);
        NSString *documentsDirectory    = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSMutableSet *pathsToKeep       = [NSMutableSet set];
        for (NSDictionary *mediaDict in mediaObjectsToKeep) {
            NSString *path = mediaDict[localUrlProperty];
            if (path) {
                NSString *absolutePath = [documentsDirectory stringByAppendingPathComponent:path];
                [pathsToKeep addObject:absolutePath];
            }

            NSString *thumbPath = mediaDict[localThumbUrlProperty];
            if (thumbPath) {
                NSString *absoluteThumbPath = [documentsDirectory stringByAppendingPathComponent:thumbPath];
                [pathsToKeep addObject:absoluteThumbPath];
            }
        }

        // Search for media extension files within the Media Folder
        NSSet *mediaExtensions = [NSSet setWithObjects:@"jpg", @"jpeg", @"png", @"gif", @"mov", @"avi", @"mp4", nil];

        NSArray *contentsOfDir = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[self urlForMediaDirectory]
                                                               includingPropertiesForKeys:nil
                                                                                  options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                                    error:nil];

        for (NSURL *currentURL in contentsOfDir) {
            NSString *filepath = [[currentURL URLByResolvingSymlinksInPath] path];
            NSString *extension = filepath.pathExtension.lowercaseString;
            if (![mediaExtensions containsObject:extension] ||
                [pathsToKeep containsObject:filepath]) {
                continue;
            }

            NSError *nukeError = nil;
            if ([[NSFileManager defaultManager] fileExistsAtPath:filepath] &&
                [[NSFileManager defaultManager] removeItemAtPath:filepath error:&nukeError] == NO) {
                DDLogError(@"Error [%@] while nuking unused Media at path [%@]", nukeError.localizedDescription, filepath);
            }
        }
    }];
}

+ (void)cleanMediaCacheFolder
{
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));

    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    [context performBlockAndWait:^{

        // Fetch Media URL's and return them as Dictionary Results:
        // This way we'll avoid any CoreData Faulting Exception due to deletions performed on another context
        NSString *localUrlProperty = NSStringFromSelector(@selector(localURL));
        NSString *localThumbUrlProperty = NSStringFromSelector(@selector(localThumbnailURL));

        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        fetchRequest.entity = [NSEntityDescription entityForName:NSStringFromClass([Media class]) inManagedObjectContext:context];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"remoteURL == NULL"];

        fetchRequest.propertiesToFetch = @[ localUrlProperty, localThumbUrlProperty ];
        fetchRequest.resultType = NSDictionaryResultType;

        NSError *error = nil;
        NSArray *mediaObjectsToKeep = [context executeFetchRequest:fetchRequest error:&error];

        if (error) {
            DDLogError(@"Error cleaning up tmp files: %@", error.localizedDescription);
            return;
        }

        // Get a references to media files that only exist locally
        DDLogInfo(@"%i media items to check for cleanup", mediaObjectsToKeep.count);
        NSString *documentsDirectory    = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSMutableSet *pathsToKeep       = [NSMutableSet set];
        for (NSDictionary *mediaDict in mediaObjectsToKeep) {
            NSString *path = mediaDict[localUrlProperty];
            if (path) {
                NSString *absolutePath = [documentsDirectory stringByAppendingPathComponent:path];
                [pathsToKeep addObject:absolutePath];
            }

            NSString *thumbPath = mediaDict[localThumbUrlProperty];
            if (thumbPath) {
                NSString *absoluteThumbPath = [documentsDirectory stringByAppendingPathComponent:thumbPath];
                [pathsToKeep addObject:absoluteThumbPath];
            }
        }

        [self cleanFolderURL:[self urlForMediaDirectory] exceptFiles:pathsToKeep];
    }];
}

+ (void)cleanFolderURL:(NSURL *)folderURL exceptFiles:(NSSet *)exceptFiles {
    NSArray *contentsOfDir = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:folderURL
                                                           includingPropertiesForKeys:nil
                                                                              options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                                error:nil];

    for (NSURL *currentURL in contentsOfDir) {
        NSString *filepath = [[currentURL URLByResolvingSymlinksInPath] path];        
        if ([exceptFiles containsObject:filepath]) {
            continue;
        }

        NSError *nukeError = nil;
        if ([[NSFileManager defaultManager] fileExistsAtPath:filepath] &&
            [[NSFileManager defaultManager] removeItemAtPath:filepath error:&nukeError] == NO) {
            DDLogError(@"Error [%@] while nuking unused Media at path [%@]", nukeError.localizedDescription, filepath);
        }
    }
}


@end
