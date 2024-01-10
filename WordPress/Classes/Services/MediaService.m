#import "MediaService.h"
#import "AccountService.h"
#import "Media.h"
#import "WPAccount.h"
#import "CoreDataStack.h"
#import "Blog.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "WordPress-Swift.h"
#import "WPXMLRPCDecoder.h"
#import <WordPressShared/WPImageSource.h>
#import <WordPressShared/WPAnalytics.h>

@import WordPressKit;
@import WordPressUI;
@import WordPressShared;

NSErrorDomain const MediaServiceErrorDomain = @"MediaServiceErrorDomain";

@implementation MediaService

#pragma mark - Uploading media

- (BOOL)isValidFileInMedia:(Media *)media error:(NSError **)error {
    Blog *blog = media.blog;
    if (media.absoluteLocalURL == nil || ![media.absoluteLocalURL checkResourceIsReachableAndReturnError:nil]) {
        if (error){
            *error = [NSError errorWithDomain:MediaServiceErrorDomain
                                         code:MediaServiceErrorFileDoesNotExist
                                     userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Media doesn't have an associated file to upload.", @"Error message to show to users when trying to upload a media object with no local file associated")}];
        }
        return NO;
    }

    if (![blog hasSpaceAvailableFor:media.absoluteLocalURL]) {
        if (error) {
            NSString *errorReason = NSLocalizedString(@"Not enough space to upload", @"Error message to show to users when trying to upload a media object with file size is larger than the available site disk quota");
            NSString *quotaInfo = blog.quotaUsageDescription;
            NSString *errorMessage = errorReason;
            if (quotaInfo != nil) {
                errorMessage = [NSString stringWithFormat:@"%@\n%@", errorReason, quotaInfo];
            }
            *error = [NSError errorWithDomain:MediaServiceErrorDomain
                                         code:MediaServiceErrorFileLargerThanDiskQuotaAvailable
                                     userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
        }
        return NO;
    }

    if (![blog isAbleToHandleFileSizeOfUrl:media.absoluteLocalURL]) {
        if (error) {
            NSNumber *fileSize = media.absoluteLocalURL.fileSize;
            NSString *fileSizeDescription = [NSByteCountFormatter stringFromByteCount:fileSize.longLongValue countStyle:NSByteCountFormatterCountStyleBinary];
            NSNumber *maxFileSize = blog.maxUploadSize;
            NSString *maxFileSizeDescription = [NSByteCountFormatter stringFromByteCount:maxFileSize.longLongValue countStyle:NSByteCountFormatterCountStyleBinary];
            NSString *errorLocalized = NSLocalizedString(@"Media filesize (%@) is too large to upload. Maximum allowed is %@", @"Error message to show to users when trying to upload a media object with file size is larger than the max file size allowed in the site");
            NSString *errorMessage = [NSString stringWithFormat:errorLocalized, fileSizeDescription, maxFileSizeDescription];
            *error = [NSError errorWithDomain:MediaServiceErrorDomain
                                         code:MediaServiceErrorFileLargerThanMaxFileSize
                                     userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
        }
        return NO;
    }

    return YES;
}

- (void)uploadMedia:(Media *)media
     automatedRetry:(BOOL)automatedRetry
           progress:(NSProgress **)progress
            success:(void (^)(void))success
            failure:(void (^)(NSError *error))failure
{
    Blog *blog = media.blog;
    id<MediaServiceRemote> remote = [self remoteForBlog:blog];
    RemoteMedia *remoteMedia = [RemoteMedia remoteMediaWithMedia:media];
    // Even though jpeg is a valid extension, use jpg instead for the widest possible
    // support.  Some third-party image related plugins prefer the .jpg extension.
    // See https://github.com/wordpress-mobile/WordPress-iOS/issues/4663
    remoteMedia.file = [remoteMedia.file stringByReplacingOccurrencesOfString:@".jpeg" withString:@".jpg"];
    NSManagedObjectID *mediaObjectID = media.objectID;

    void (^failureBlock)(NSError *error) = ^(NSError *error) {
        [self.managedObjectContext performBlock:^{
            if (error) {
                [self trackUploadError:error blog:blog];
                DDLogError(@"Error uploading media: %@", error);
            }
            NSError *customError = [self customMediaUploadError:error remote:remote];
            Media *mediaInContext = (Media *)[self.managedObjectContext existingObjectWithID:mediaObjectID error:nil];
            if (mediaInContext) {
                mediaInContext.remoteStatus = MediaRemoteStatusFailed;
                mediaInContext.error = customError;

                if (automatedRetry) {
                    [mediaInContext incrementAutoUploadFailureCount];
                }

                [[ContextManager sharedInstance] saveContext:self.managedObjectContext withCompletionBlock:^{
                    if (failure) {
                        failure(customError);
                    }
                } onQueue:dispatch_get_main_queue()];
                return;
            }
            if (failure) {
                failure(customError);
            }
        }];
    };

    NSError *mediaValidationError = nil;
    if (![self isValidFileInMedia:media error: &mediaValidationError]) {
        if(progress) {
            *progress = [NSProgress discreteProgressWithTotalUnitCount:1];
        }
        failureBlock(mediaValidationError);
        return;
    }

    [self.managedObjectContext performBlock:^{
        Media *mediaInContext = (Media *)[self.managedObjectContext existingObjectWithID:mediaObjectID error:nil];
        if (mediaInContext) {
            mediaInContext.remoteStatus = MediaRemoteStatusPushing;
            mediaInContext.error = nil;

            if (!automatedRetry) {
                [mediaInContext resetAutoUploadFailureCount];
            }

            [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
        }
    }];
    void (^successBlock)(RemoteMedia *media) = ^(RemoteMedia *media) {
        [self.managedObjectContext performBlock:^{
            [WPAppAnalytics track:WPAnalyticsStatMediaServiceUploadSuccessful withBlog:blog];
            NSError * error = nil;
            Media *mediaInContext = (Media *)[self.managedObjectContext existingObjectWithID:mediaObjectID error:&error];
            if (!mediaInContext){
                DDLogError(@"Error retrieving media object: %@", error);
                if (failure){
                    failureBlock(error);
                }
                return;
            }

            [MediaHelper updateMedia:mediaInContext withRemoteMedia:media];
            [[ContextManager sharedInstance] saveContext:self.managedObjectContext withCompletionBlock:^{
                if (success) {
                    success();
                }
            } onQueue:dispatch_get_main_queue()];
        }];
    };

    [self.managedObjectContext performBlock:^{
        [WPAppAnalytics track:WPAnalyticsStatMediaServiceUploadStarted withBlog:blog];
    }];

    [remote uploadMedia:remoteMedia
               progress:progress
                success:successBlock
                failure:failureBlock];
}

#pragma mark - Private helpers

- (void)trackUploadError:(NSError *)error
                    blog:(Blog *)blog
{
    if (error.code == NSURLErrorCancelled) {
        [WPAppAnalytics track:WPAnalyticsStatMediaServiceUploadCanceled withBlog:blog];
    } else {
        [WPAppAnalytics track:WPAnalyticsStatMediaServiceUploadFailed error:error withBlogID:blog.dotComID];
    }
}

#pragma mark - Updating media

- (void)updateMedia:(Media *)media
            fieldsToUpdate:(NSArray<NSString *> *)fieldsToUpdate
            success:(void (^)(void))success
            failure:(void (^)(NSError *error))failure
{
    RemoteMedia *remoteMedia;
    if (fieldsToUpdate != nil && [fieldsToUpdate count] > 0) {
        remoteMedia = [self remoteMediaFromMedia:media fieldsToUpdate:fieldsToUpdate];
    } else {
        remoteMedia = [RemoteMedia remoteMediaWithMedia:media];
    }

    id<MediaServiceRemote> remote = [self remoteForBlog:media.blog];
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

            [MediaHelper updateMedia:mediaInContext withRemoteMedia:media];
            [[ContextManager sharedInstance] saveContext:self.managedObjectContext withCompletionBlock:^{
                if (success) {
                    success();
                }
            } onQueue:dispatch_get_main_queue()];
        }];
    };
    void (^failureBlock)(NSError *error) = ^(NSError *error) {
        [self.managedObjectContext performBlock:^{
            Media *mediaInContext = (Media *)[self.managedObjectContext existingObjectWithID:mediaObjectID error:nil];
            if (mediaInContext) {
                [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
            }
            if (failure) {
                failure(error);
            }
        }];
    };

    [remote updateMedia:remoteMedia
                success:successBlock
                failure:failureBlock];
}

- (void)updateMedia:(Media *)media
            success:(void (^)(void))success
            failure:(void (^)(NSError *error))failure
{
    [self updateMedia:media fieldsToUpdate:nil success:success failure:failure];
}

- (void)updateMedia:(NSArray<Media *> *)mediaObjects
            fieldsToUpdate:(NSArray<NSString *> *)fieldsToUpdate
            overallSuccess:(void (^)(void))overallSuccess
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
        [self updateMedia:media fieldsToUpdate:fieldsToUpdate success:^{
            individualOperationCompletion(true);
        } failure:^(NSError * __unused error) {
            individualOperationCompletion(false);
        }];
    }
}

- (void)updateMedia:(NSArray<Media *> *)mediaObjects
     overallSuccess:(void (^)(void))overallSuccess
            failure:(void (^)(NSError *error))failure
{
    [self updateMedia:mediaObjects fieldsToUpdate:nil overallSuccess:overallSuccess failure:failure];
}

#pragma mark - Private helpers

- (NSError *)customMediaUploadError:(NSError *)error remote:(id <MediaServiceRemote>)remote {
    NSString *customErrorMessage = nil;
    if ([remote isKindOfClass:[MediaServiceRemoteXMLRPC class]]) {
        // For self-hosted sites we should generally pass on the raw system/network error message.
        // Which should help debug issues with a self-hosted site.
        if ([error.domain isEqualToString:WordPressOrgXMLRPCApiErrorDomain] && [error.userInfo objectForKey:WordPressOrgXMLRPCApi.WordPressOrgXMLRPCApiErrorKeyStatusCode] != nil) {
            NSNumber *errorCode = (NSNumber *)[error.userInfo objectForKey:WordPressOrgXMLRPCApi.WordPressOrgXMLRPCApiErrorKeyStatusCode];
            switch (errorCode.intValue) {
                case 500:{
                    customErrorMessage = NSLocalizedString(@"This file is too large to upload to your site or it does not support this media format.", @"Message to show to user when media upload failed because server doesn't support media type");
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
                    customErrorMessage = NSLocalizedString(@"An unknown error occurred. Please try again.", @"Error message shown when a media upload fails for unknown reason and the user should try again.");
                    break;
                case NSURLErrorNetworkConnectionLost:
                case NSURLErrorNotConnectedToInternet:
                    // Clear lack of device internet connection, notify the user
                    customErrorMessage = NSLocalizedString(@"The Internet connection appears to be offline.", @"Error message shown when a media upload fails because the user isn't connected to the Internet.");
                    break;
                default:
                    // Default NSURL error messaging, probably server-side, encourage user to try again
                    customErrorMessage = NSLocalizedString(@"Something went wrong. Please try again.", @"Error message shown when a media upload fails for a general network issue and the user should try again in a moment.");
                    break;
            }
        }
    }

    if (customErrorMessage) {
        NSMutableDictionary *userInfo = [error.userInfo mutableCopy];
        userInfo[NSLocalizedDescriptionKey] = customErrorMessage;
        error = [NSError errorWithDomain:error.domain code:error.code userInfo:userInfo];
    }

    return error;
}

#pragma mark - Deleting media

- (void)deleteMedia:(nonnull Media *)media
            success:(nullable void (^)(void))success
            failure:(nullable void (^)(NSError * _Nonnull error))failure
{
    NSManagedObjectID *mediaObjectID = media.objectID;

    void (^successBlock)(void) = ^() {
        [self.managedObjectContext performBlock:^{
            Media *mediaInContext = (Media *)[self.managedObjectContext existingObjectWithID:mediaObjectID error:nil];

            if (mediaInContext == nil) {
                // Considering the intent of calling this method is to delete the media object,
                // when it doesn't exist, we can simply signal success, since the intent is fulfilled.
                success();
                return;
            }

            [self.managedObjectContext deleteObject:mediaInContext];
            [[ContextManager sharedInstance] saveContext:self.managedObjectContext
                                     withCompletionBlock:success
                                                 onQueue:dispatch_get_main_queue()];
        }];
    };

    if (media.remoteStatus != MediaRemoteStatusSync) {
        successBlock();
        return;
    }

    id<MediaServiceRemote> remote = [self remoteForBlog:media.blog];
    RemoteMedia *remoteMedia = [RemoteMedia remoteMediaWithMedia:media];

    [remote deleteMedia:remoteMedia
                success:successBlock
                failure:failure];
}

- (void)deleteMedia:(nonnull NSArray<Media *> *)mediaObjects
           progress:(nullable void (^)(NSProgress *_Nonnull progress))progress
            success:(nullable void (^)(void))success
            failure:(nullable void (^)(void))failure
{
    if (mediaObjects.count == 0) {
        if (success) {
            success();
        }
        return;
    }

    NSProgress *currentProgress = [NSProgress progressWithTotalUnitCount:mediaObjects.count];

    dispatch_group_t group = dispatch_group_create();

    [mediaObjects enumerateObjectsUsingBlock:^(Media *media, NSUInteger __unused idx, BOOL * __unused stop) {
        dispatch_group_enter(group);
        [self deleteMedia:media success:^{
            currentProgress.completedUnitCount++;
            if (progress) {
                progress(currentProgress);
            }
            dispatch_group_leave(group);
        } failure:^(NSError * __unused error) {
            dispatch_group_leave(group);
        }];
    }];

    // After all the operations have succeeded (or failed)
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (currentProgress.completedUnitCount >= currentProgress.totalUnitCount) {
            if (success) {
                success();
            }
        } else {
            if (failure) {
                failure();
            }
        }
    });
}

- (void)syncMediaLibraryForBlog:(Blog *)blog
                        success:(void (^)(void))success
                        failure:(void (^)(NSError *error))failure
{
    __block BOOL onePageLoad = NO;
    NSManagedObjectID *blogObjectID = [blog objectID];

    if (blog == nil || blogObjectID == nil) {
        NSError *error = [NSError errorWithDomain:WKErrorDomain code:WKErrorUnknown userInfo:@{NSDebugDescriptionErrorKey: @"Failed to get blogObjectID for syncMediaLibraryForBlog"}];
        [WordPressAppDelegate logError:error];
        return;
    }

    [self.managedObjectContext performBlock:^{
        NSError *error = nil;
        Blog *blogInContext = (Blog *)[self.managedObjectContext existingObjectWithID:blogObjectID error:&error];

        if (!blogInContext) {
            failure(error);
            return;
        }

        NSSet *originalLocalMedia = blogInContext.media;
        id<MediaServiceRemote> remote = [self remoteForBlog:blogInContext];
        [remote getMediaLibraryWithPageLoad:^(NSArray *media) {
                                    [self.managedObjectContext performBlock:^{
                                        void (^completion)(void) = nil;
                                        if (!onePageLoad) {
                                            onePageLoad = YES;
                                            completion = success;
                                        }
                                        [self mergeMedia:media forBlog:blogInContext baseMedia:originalLocalMedia deleteUnreferencedMedia:NO completionHandler:completion];
                                    }];
                                }
                               success:^(NSArray *media) {
                                   [self.managedObjectContext performBlock:^{
                                       [self mergeMedia:media forBlog:blogInContext baseMedia:originalLocalMedia deleteUnreferencedMedia:YES completionHandler:success];
                                   }];
                               }
                               failure:^(NSError *error) {
                                   if (failure) {
                                       [self.managedObjectContext performBlock:^{
                                           failure(error);
                                       }];
                                   }
                               }];
    }];
}

#pragma mark - Private helpers

- (NSString *)mimeTypeForMediaType:(NSNumber *)mediaType
{
    MediaType filter = (MediaType)[mediaType intValue];
    NSString *mimeType = [Media stringFromMediaType:filter];
    return mimeType;
}

#pragma mark - Media helpers

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
         baseMedia:(NSSet *)originalBlogMedia
deleteUnreferencedMedia:(BOOL)deleteUnreferencedMedia
 completionHandler:(void (^)(void))completion
{
    NSParameterAssert(blog);
    NSParameterAssert(media);
    NSMutableSet *mediaToKeep = [NSMutableSet set];
    for (RemoteMedia *remote in media) {
        @autoreleasepool {
            Media *local = [Media existingMediaWithMediaID:remote.mediaID inBlog:blog];
            if (!local) {
                local = [Media makeMediaWithBlog:blog];
            }
            [MediaHelper updateMedia:local withRemoteMedia:remote];
            [mediaToKeep addObject:local];
        }
    }
    if (deleteUnreferencedMedia) {
        NSMutableSet *mediaToDelete = [NSMutableSet setWithSet:originalBlogMedia];
        [mediaToDelete minusSet:mediaToKeep];
        for (Media *deleteMedia in mediaToDelete) {
            // only delete media that is server based
            if ([deleteMedia.mediaID intValue] > 0) {
                [self.managedObjectContext deleteObject:deleteMedia];
            }
        }
    }
    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    if (completion) {
        completion();
    }
}

- (RemoteMedia *)remoteMediaFromMedia:(Media *)media fieldsToUpdate:(NSArray<NSString *> *)fieldsToUpdate
{
    RemoteMedia *remoteMedia = [[RemoteMedia alloc] init];
    remoteMedia.mediaID = media.mediaID;

    NSMutableDictionary *updateDict = [NSMutableDictionary dictionary];
    for (NSString *field in fieldsToUpdate) {
        id value = [media valueForKey:field];
        if (value) {
            if ([field isEqualToString: @"fileExtension"]) {
                updateDict[field] = [media fileExtension] ?: @"unknown";
            } else if ([field isEqualToString: @"mimeType"]) {
                updateDict[field] = media.mimeType;
            } else {
                updateDict[field] = value;
            }
        }
    }

    remoteMedia.url = [NSURL URLWithString:updateDict[@"remoteURL"]];
    remoteMedia.largeURL = [NSURL URLWithString:updateDict[@"remoteLargeURL"]];
    remoteMedia.mediumURL = [NSURL URLWithString:updateDict[@"remoteMediumURL"]];
    remoteMedia.date = updateDict[@"creationDate"];
    remoteMedia.file = updateDict[@"filename"];
    remoteMedia.extension = updateDict[@"fileExtension"];
    remoteMedia.title = updateDict[@"title"];
    remoteMedia.caption = updateDict[@"caption"];
    remoteMedia.descriptionText = updateDict[@"desc"];
    remoteMedia.alt = updateDict[@"alt"];
    remoteMedia.height = updateDict[@"height"];
    remoteMedia.width = updateDict[@"width"];
    remoteMedia.localURL = updateDict[@"absoluteLocalURL"];
    remoteMedia.mimeType = updateDict[@"mimeType"];
    remoteMedia.videopressGUID = updateDict[@"videopressGUID"];
    remoteMedia.remoteThumbnailURL = updateDict[@"remoteThumbnailURL"];
    remoteMedia.postID = updateDict[@"postID"];
    return remoteMedia;
}

- (NSMutableDictionary *)blogPropertiesToTrack:(Blog *)blog {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    BOOL isJetpackConnected = blog.jetpack != nil && blog.jetpack.isConnected;
    
    properties[WPAppAnalyticsKeyIsJetpack] = @(isJetpackConnected);
    properties[WPAppAnalyticsKeyIsAtomic] = @(blog.isAtomic);
    properties[WPAppAnalyticsKeyIsHostedAtWPcom] = @(blog.isHostedAtWPcom);

    return properties;
}

@end
