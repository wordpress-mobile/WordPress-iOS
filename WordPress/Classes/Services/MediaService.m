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

@interface MediaService ()

@property (nonatomic, strong) MediaThumbnailService *thumbnailService;

@end

@implementation MediaService

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context
{
    self = [super initWithManagedObjectContext:context];
    if (self) {
        _concurrentThumbnailGeneration = NO;
    }
    return self;
}

#pragma mark - Creating media

- (Media *)createMediaWith:(id<ExportableAsset>)exportable
                      blog:(Blog *)blog
                      post:(AbstractPost *)post
                  progress:(NSProgress **)progress
         thumbnailCallback:(void (^)(Media *media, NSURL *thumbnailURL))thumbnailCallback
                completion:(void (^)(Media *media, NSError *error))completion
{
    NSParameterAssert(post == nil || blog == post.blog);
    NSParameterAssert(blog.managedObjectContext == self.managedObjectContext);
    NSProgress *createProgress = [NSProgress discreteProgressWithTotalUnitCount:1];
    __block Media *media;
    __block NSSet<NSString *> *allowedFileTypes = [NSSet set];
    [self.managedObjectContext performBlockAndWait:^{
        if ( blog == nil ) {
            if (completion) {
                NSError *error = [NSError errorWithDomain: MediaServiceErrorDomain code: MediaServiceErrorUnableToCreateMedia userInfo: nil];
                completion(nil, error);
            }
            return;
        }
        
        if (blog.allowedFileTypes != nil) {
            // HEIC isn't supported when uploading an image, so we filter it out (http://git.io/JJAae)
            NSMutableSet *mutableAllowedFileTypes = [blog.allowedFileTypes mutableCopy];
            [mutableAllowedFileTypes removeObject:@"heic"];
            allowedFileTypes = mutableAllowedFileTypes;
        }

        if (post != nil) {
            media = [Media makeMediaWithPost:post];
        } else {
            media = [Media makeMediaWithBlog:blog];
        }
        media.mediaType = exportable.assetMediaType;
        media.remoteStatus = MediaRemoteStatusProcessing;

        [self.managedObjectContext obtainPermanentIDsForObjects:@[media] error:nil];
        [[ContextManager sharedInstance] saveContextAndWait:self.managedObjectContext];
    }];
    if (media == nil) {
        return nil;
    }
    NSManagedObjectID *mediaObjectID = media.objectID;
    [self.managedObjectContext performBlock:^{
        // Setup completion handlers
        void(^completionWithMedia)(Media *) = ^(Media *media) {
            media.remoteStatus = MediaRemoteStatusLocal;
            media.error = nil;
            // Pre-generate a thumbnail image, see the method notes.
            [self exportPlaceholderThumbnailForMedia:media
                                          completion:^(NSURL *url){
                                              if (thumbnailCallback) {
                                                  thumbnailCallback(media, url);
                                              }
                                          }];
            if (completion) {
                completion(media, nil);
            }
        };
        void(^completionWithError)( NSError *) = ^(NSError *error) {
            Media *mediaInContext = (Media *)[self.managedObjectContext existingObjectWithID:mediaObjectID error:nil];
            if (mediaInContext) {
                mediaInContext.error = error;
                mediaInContext.remoteStatus = MediaRemoteStatusFailed;
                [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
            }
            if (completion) {
                completion(media, error);
            }
        };

        // Export based on the type of the exportable.
        MediaImportService *importService = [[MediaImportService alloc] initWithManagedObjectContext:self.managedObjectContext];
        importService.allowableFileExtensions = allowedFileTypes;
        NSProgress *importProgress = [importService importResource:exportable toMedia:media onCompletion:completionWithMedia onError:completionWithError];
        [createProgress addChild:importProgress withPendingUnitCount:1];
    }];
    if (progress != nil) {
        *progress = createProgress;
    }
    return media;
}

/**
 Generate a thumbnail image for the Media asset so that consumers of the absoluteThumbnailLocalURL property
 will have an image ready to load, without using the async methods provided via MediaThumbnailService.
 
 This is primarily used as a placeholder image throughout the code-base, particulary within the editors.
 
 Note: Ideally we wouldn't need this at all, but the synchronous usage of absoluteThumbnailLocalURL across the code-base
       to load a thumbnail image is relied on quite heavily. In the future, transitioning to asynchronous thumbnail loading
       via the new thumbnail service methods is much preferred, but would indeed take a good bit of refactoring away from
       using absoluteThumbnailLocalURL.
*/
- (void)exportPlaceholderThumbnailForMedia:(Media *)media completion:(void (^)(NSURL *thumbnailURL))thumbnailCallback
{
    [self.thumbnailService thumbnailURLForMedia:media
                                  preferredSize:CGSizeZero
                                   onCompletion:^(NSURL *url) {
                                       [self.managedObjectContext performBlock:^{
                                           if (url) {
                                               // Set the absoluteThumbnailLocalURL with the generated thumbnail's URL.
                                               media.absoluteThumbnailLocalURL = url;
                                               [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
                                           }
                                           if (thumbnailCallback) {
                                               thumbnailCallback(url);
                                           }
                                       }];
                                   }
                                        onError:^(NSError *error) {
                                            DDLogError(@"Error occurred exporting placeholder thumbnail: %@", error);
                                        }];
}

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
    RemoteMedia *remoteMedia = [self remoteMediaFromMedia:media];
    // Even though jpeg is a valid extension, use jpg instead for the widest possible
    // support.  Some third-party image related plugins prefer the .jpg extension.
    // See https://github.com/wordpress-mobile/WordPress-iOS/issues/4663
    remoteMedia.file = [remoteMedia.file stringByReplacingOccurrencesOfString:@".jpeg" withString:@".jpg"];
    NSManagedObjectID *mediaObjectID = media.objectID;

    void (^failureBlock)(NSError *error) = ^(NSError *error) {
        [self.managedObjectContext performBlock:^{
            if (error) {
                [self trackUploadError:error];
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

            [self updateMedia:mediaInContext withRemoteMedia:media];
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
{
    if (error.code == NSURLErrorCancelled) {
        [WPAppAnalytics track:WPAnalyticsStatMediaServiceUploadCanceled];
    } else {
        [WPAppAnalytics track:WPAnalyticsStatMediaServiceUploadFailed error:error];
    }
}

#pragma mark - Updating media

- (void)updateMedia:(Media *)media
            success:(void (^)(void))success
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

- (void)updateMedia:(NSArray<Media *> *)mediaObjects
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
        [self updateMedia:media success:^{
            individualOperationCompletion(true);
        } failure:^(NSError *error) {
            individualOperationCompletion(false);
        }];
    }
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
    RemoteMedia *remoteMedia = [self remoteMediaFromMedia:media];
    
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

    [mediaObjects enumerateObjectsUsingBlock:^(Media *media, NSUInteger idx, BOOL *stop) {
        dispatch_group_enter(group);
        [self deleteMedia:media success:^{
            currentProgress.completedUnitCount++;
            if (progress) {
                progress(currentProgress);
            }
            dispatch_group_leave(group);
        } failure:^(NSError *error) {
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

#pragma mark - Getting media

- (void) getMediaWithID:(NSNumber *) mediaID inBlog:(Blog *) blog
                success:(void (^)(Media *media))success
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
           Media *media = [Media existingMediaWithMediaID:remoteMedia.mediaID inBlog:blog];
           if (!media) {
               media = [Media makeMediaWithBlog:blog];
           }
           [self updateMedia:media withRemoteMedia:remoteMedia];

           [[ContextManager sharedInstance] saveContextAndWait:self.managedObjectContext];

           if (success){
               success(media);

               if ([media hasChanges]) {
                   NSCAssert(NO, @"The success callback should not modify the Media instance");
                   [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
               }
           }
       }];
    } failure:^(NSError *error) {
        if (failure) {
            [self.managedObjectContext performBlock:^{
                failure(error);
            }];
        }

    }];
}

- (void)getMetadataFromVideoPressID:(NSString *)videoPressID
                             inBlog:(Blog *)blog
                            success:(void (^)(RemoteVideoPressVideo *metadata))success
                            failure:(void (^)(NSError *error))failure
{
    id<MediaServiceRemote> remote = [self remoteForBlog:blog];
    [remote getMetadataFromVideoPressID:videoPressID isSitePrivate:blog.isPrivate success:^(RemoteVideoPressVideo *metadata) {
        if (success) {
            success(metadata);
        }
    } failure:^(NSError * error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)syncMediaLibraryForBlog:(Blog *)blog
                        success:(void (^)(void))success
                        failure:(void (^)(NSError *error))failure
{    
    __block BOOL onePageLoad = NO;
    NSManagedObjectID *blogObjectID = [blog objectID];
    
    /// Temporary logging to try and narrow down an issue:
    ///
    /// REF: https://github.com/wordpress-mobile/WordPress-iOS/issues/15335
    ///
    if (blog == nil || blog.objectID == nil) {
        DDLogError(@"🔴 Error: missing object ID (please contact @diegoreymendez with this log)");
        DDLogError(@"%@", [NSThread callStackSymbols]);
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

- (void)getMediaLibraryServerCountForBlog:(Blog *)blog
                            forMediaTypes:(NSSet *)mediaTypes
                                  success:(void (^)(NSInteger count))success
                                  failure:(void (^)(NSError *error))failure
{
    NSMutableSet *remainingMediaTypes = [NSMutableSet setWithSet:mediaTypes];
    NSNumber *currentMediaType = [mediaTypes anyObject];
    NSString *currentMimeType = nil;
    if (currentMediaType != nil) {
        currentMimeType = [self mimeTypeForMediaType:currentMediaType];
        [remainingMediaTypes removeObject:currentMediaType];
    }
    id<MediaServiceRemote> remote = [self remoteForBlog:blog];
    [remote getMediaLibraryCountForType:currentMimeType
                            withSuccess:^(NSInteger count) {
        if( remainingMediaTypes.count == 0) {
            if (success) {
                success(count);
            }
        } else {
            [self getMediaLibraryServerCountForBlog:blog forMediaTypes:remainingMediaTypes success:^(NSInteger otherCount) {
                if (success) {
                    success(count + otherCount);
                }
            } failure:^(NSError * _Nonnull error) {
                if (failure) {
                    failure(error);
                }
            }];
        }
    } failure:^(NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

#pragma mark - Thumbnails

- (MediaThumbnailService *)thumbnailService
{
    if (!_thumbnailService) {
        _thumbnailService = [[MediaThumbnailService alloc] initWithContextManager:[ContextManager sharedInstance]];
        if (self.concurrentThumbnailGeneration) {
            _thumbnailService.exportQueue = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0);
        }
    }
    return _thumbnailService;
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
            [self updateMedia:local withRemoteMedia:remote];
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

- (RemoteMedia *)remoteMediaFromMedia:(Media *)media
{
    RemoteMedia *remoteMedia = [[RemoteMedia alloc] init];
    remoteMedia.mediaID = media.mediaID;
    remoteMedia.url = [NSURL URLWithString:media.remoteURL];
    remoteMedia.largeURL = [NSURL URLWithString:media.remoteLargeURL];
    remoteMedia.mediumURL = [NSURL URLWithString:media.remoteMediumURL];
    remoteMedia.date = media.creationDate;
    remoteMedia.file = media.filename;
    remoteMedia.extension = [media fileExtension] ?: @"unknown";
    remoteMedia.title = media.title;
    remoteMedia.caption = media.caption;
    remoteMedia.descriptionText = media.desc;
    remoteMedia.alt = media.alt;
    remoteMedia.height = media.height;
    remoteMedia.width = media.width;
    remoteMedia.localURL = media.absoluteLocalURL;
    remoteMedia.mimeType = [media mimeType];
	remoteMedia.videopressGUID = media.videopressGUID;
    remoteMedia.remoteThumbnailURL = media.remoteThumbnailURL;
    remoteMedia.postID = media.postID;
    return remoteMedia;
}

@end
