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
#import "WordPress-swift.h"
#import <WordPressApi/WordPressApi.h>
#import "WPXMLRPCDecoder.h"
#import "WordPressComApi.h"

@implementation MediaService

- (void)createMediaWithPHAsset:(PHAsset *)asset
             forPostObjectID:(NSManagedObjectID *)postObjectID
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
    MediaType mediaType = MediaTypeDocument;
    NSSet *allowedFileTypes = nil;
    NSString *assetUTI = [asset originalUTI];
    NSString *extension = [self extensionForUTI:assetUTI];
    if (asset.mediaType == PHAssetMediaTypeImage) {
        mediaType = MediaTypeImage;
        allowedFileTypes = post.blog.allowedFileTypes;
        if (![allowedFileTypes containsObject:extension]) {
            assetUTI = (__bridge NSString *)kUTTypeJPEG;
            extension = [self extensionForUTI:assetUTI];
        }
    } else if (asset.mediaType == PHAssetMediaTypeVideo) {
        /** HACK: Sergio Estevao (2015-11-09): We ignore allowsFileTypes for videos in WP.com
         because we have an exception on the server for mobile that allows video uploads event 
         if videopress is not enabled.
        */
        if (![post.blog isHostedAtWPcom] && ![allowedFileTypes containsObject:extension]) {
            assetUTI = (__bridge NSString *)kUTTypeQuickTimeMovie;
            extension = [self extensionForUTI:assetUTI];
        }
        allowedFileTypes = nil;
        mediaType = MediaTypeVideo;
    }
    
    BOOL geoLocationEnabled = post.blog.settings.geolocationEnabled;
    
    NSInteger maxImageSize = [[MediaSettings new] imageSizeForUpload];
    CGSize maximumResolution = CGSizeMake(maxImageSize, maxImageSize);

    NSURL *mediaURL = [self urlForMediaWithFilename:[asset originalFilename] andExtension:extension];
    NSURL *mediaThumbnailURL = [self urlForMediaWithFilename:[self pathForThumbnailOfFile:[mediaURL lastPathComponent]]
                                                andExtension:[self extensionForUTI:[asset defaultThumbnailUTI]]];
    
    [[self.class queueForResizeMediaOperations] addOperationWithBlock:^{
        [asset exportThumbnailToURL:mediaThumbnailURL
                         targetSize:[UIScreen mainScreen].bounds.size
                        synchronous:YES
                     successHandler:^(CGSize thumbnailSize) {
            if (thumbnailCallback) {
                thumbnailCallback(mediaThumbnailURL);
            }

            [asset exportToURL:mediaURL
                     targetUTI:assetUTI
             maximumResolution:maximumResolution
              stripGeoLocation:!geoLocationEnabled
                successHandler:^(CGSize resultingSize)
                {
                    [self createMediaForPost:postObjectID
                                    mediaURL:mediaURL
                           mediaThumbnailURL:mediaThumbnailURL
                                   mediaType:mediaType
                                   mediaSize:resultingSize
                                  completion:completion];
                }
                errorHandler:^(NSError *error) {
                   if (completion){
                       completion(nil, error);
                   }
                }];
            } errorHandler:^(NSError *error) {
                if (completion){
                    completion(nil, error);
                }
            }];
    }];
}

- (void) createMediaForPost:(NSManagedObjectID *)postObjectID
                   mediaURL:(NSURL *)mediaURL
          mediaThumbnailURL:(NSURL *)mediaThumbnailURL
                  mediaType:(MediaType)mediaType
                  mediaSize:(CGSize)mediaSize
                 completion:(void (^)(Media *media, NSError *error))completion
{
 
    [self.managedObjectContext performBlock:^{
        AbstractPost *post = (AbstractPost *)[self.managedObjectContext objectWithID:postObjectID];
        Media *media = [self newMediaForPost:post];
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
                failure([self translateMediaUploadError:error]);
            }
        }];
    };
    
    [remote createMedia:remoteMedia
               progress:progress
                success:successBlock
                failure:failureBlock];
}

- (NSError *)translateMediaUploadError:(NSError *)error {
    NSError *newError = error;
    if (error.domain == WordPressComApiErrorDomain) {
        NSString *errorMessage = [error localizedDescription];
        NSInteger errorCode = error.code;
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
        switch (error.code) {
            case WordPressComApiErrorUploadFailed:
                errorMessage = NSLocalizedString(@"The app couldn't upload this media.", @"Message to show to user when media upload failed by unknow server error");
                errorCode = WordPressComApiErrorUploadFailed;
                break;
            case WordPressComApiErrorUploadFailedInvalidFileType:
                errorMessage = NSLocalizedString(@"Your site does not support this media file format.", @"Message to show to user when media upload failed because server doesn't support media type");
                errorCode = WordPressComApiErrorUploadFailedInvalidFileType;
                break;
            case WordPressComApiErrorUploadFailedNotEnoughDiskQuota:
                errorMessage = NSLocalizedString(@"Your site is out of space for media uploads.", @"Message to show to user when media upload failed because user doesn't have enough space on quota/disk");
                errorCode = WordPressComApiErrorUploadFailedNotEnoughDiskQuota;
                break;
        }
        userInfo[NSLocalizedDescriptionKey] = errorMessage;
        newError = [[NSError alloc] initWithDomain:WordPressComApiErrorDomain code:errorCode userInfo:userInfo];
    } else if (error.domain == WPXMLRPCFaultErrorDomain) {
        NSString *errorMessage = [error localizedDescription];
        NSInteger errorCode = error.code;
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
        switch (error.code) {
            case 500:{
                errorMessage = NSLocalizedString(@"Your site does not support this media file format.", @"Message to show to user when media upload failed because server doesn't support media type");
                errorCode = WordPressComApiErrorUploadFailedInvalidFileType;
            } break;
            case 401:{
                errorMessage = NSLocalizedString(@"Your site is out of space for media uploads.", @"Message to show to user when media upload failed because user doesn't have enough space on quota/disk");
                errorCode = WordPressComApiErrorUploadFailedNotEnoughDiskQuota;
            } break;
        }
        userInfo[NSLocalizedDescriptionKey] = errorMessage;
        newError = [[NSError alloc] initWithDomain:WordPressComApiErrorDomain code:errorCode userInfo:userInfo];
    }
    return newError;
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

- (void)thumbnailForMedia:(Media *)mediaInRandomContext
                 size:(CGSize)size
              success:(void (^)(UIImage *image))success
              failure:(void (^)(NSError *error))failure
{
    NSManagedObjectID *mediaID = [mediaInRandomContext objectID];
    [self.managedObjectContext performBlock:^{
        Media *media = (Media *)[self.managedObjectContext objectWithID:mediaID];
        BOOL isPrivate = media.blog.isPrivate;
        NSString *pathForFile;
        if (media.mediaType == MediaTypeImage) {
            pathForFile = media.absoluteThumbnailLocalURL;
        } else if (media.mediaType == MediaTypeVideo) {
            pathForFile = media.absoluteThumbnailLocalURL;
        }
        if (pathForFile && [[NSFileManager defaultManager] fileExistsAtPath:pathForFile isDirectory:nil]) {
            [[[self class] queueForResizeMediaOperations] addOperationWithBlock:^{
                UIImage *image = [UIImage imageWithContentsOfFile:pathForFile];
                if (success) {
                    success(image);
                }
            }];
            return;
        }
        NSURL *remoteURL = nil;
        if (media.mediaType == MediaTypeVideo) {
            remoteURL = [NSURL URLWithString:media.remoteThumbnailURL];
        } else if (media.mediaType == MediaTypeImage) {
            NSString *remote = media.remoteURL;
            if ([media.blog isHostedAtWPcom]) {
                remote = [NSString stringWithFormat:@"%@?w=%ld",remote, (long)size.width];
            }
            remoteURL = [NSURL URLWithString:remote];
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
                media.absoluteThumbnailLocalURL = [fileURL path];
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
            NSString *authToken = [[[accountService defaultWordPressComAccount] restApi] authToken];
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

- (void)getMediaLibraryCountForBlog:(Blog *)blog
                            success:(void (^)(NSInteger))success
                            failure:(void (^)(NSError *error))failure
{
    id<MediaServiceRemote> remote = [self remoteForBlog:blog];
    [remote getMediaLibraryCountWithSuccess:^(NSInteger count) {
                               if (success) {
                                   success(count);
                               }
                           }
                           failure:^(NSError *error) {
                               if (failure) {
                                   [self.managedObjectContext performBlock:^{
                                       failure(error);
                                   }];
                               }
                           }];
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

- (NSURL *)urlForMediaDirectory
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
    NSURL *mediaDirectoryURL = [self urlForMediaDirectory];
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
    if (blog.restApi) {
        remote = [[MediaServiceRemoteREST alloc] initWithApi:blog.restApi siteID:blog.dotComID];
    } else {
        WPXMLRPCClient *client = [WPXMLRPCClient clientWithXMLRPCEndpoint:[NSURL URLWithString:blog.xmlrpc]];
        remote = [[MediaServiceRemoteXMLRPC alloc] initWithApi:client username:blog.username password:blog.password];
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
    media.creationDate = remoteMedia.date;
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
    remoteMedia.mimeType = [self mimeTypeForFilename:media.localThumbnailURL];
	remoteMedia.videopressGUID = media.videopressGUID;
    remoteMedia.remoteThumbnailURL = media.remoteThumbnailURL;
    return remoteMedia;
}

#pragma mark - Media cleanup

+ (void)cleanUnusedMediaFileFromTmpDir
{
    DDLogInfo(@"%@ %@", self, NSStringFromSelector(_cmd));
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    [context performBlock:^{
        
        // Fetch Media URL's and return them as Dictionary Results:
        // This way we'll avoid any CoreData Faulting Exception due to deletions performed on another context
        NSString *localUrlProperty      = NSStringFromSelector(@selector(localURL));
        
        NSFetchRequest *fetchRequest    = [[NSFetchRequest alloc] init];
        fetchRequest.entity             = [NSEntityDescription entityForName:NSStringFromClass([Media class]) inManagedObjectContext:context];
        fetchRequest.predicate          = [NSPredicate predicateWithFormat:@"ANY posts.blog != NULL AND remoteStatusNumber <> %@", @(MediaRemoteStatusSync)];
        
        fetchRequest.propertiesToFetch  = @[ localUrlProperty ];
        fetchRequest.resultType         = NSDictionaryResultType;
        
        NSError *error = nil;
        NSArray *mediaObjectsToKeep     = [context executeFetchRequest:fetchRequest error:&error];
        
        if (error) {
            DDLogError(@"Error cleaning up tmp files: %@", error.localizedDescription);
            return;
        }
        
        // Get a references to media files linked in a post
        DDLogInfo(@"%i media items to check for cleanup", mediaObjectsToKeep.count);
        
        NSMutableSet *pathsToKeep       = [NSMutableSet set];
        for (NSDictionary *mediaDict in mediaObjectsToKeep) {
            NSString *path = mediaDict[localUrlProperty];
            if (path) {
                [pathsToKeep addObject:path];
            }
        }
        
        // Search for [JPG || JPEG || PNG || GIF] files within the Documents Folder
        NSString *documentsDirectory    = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSArray *contentsOfDir          = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil];
        
        NSSet *mediaExtensions          = [NSSet setWithObjects:@"jpg", @"jpeg", @"png", @"gif", @"mov", @"avi", @"mp4", nil];
        
        for (NSString *currentPath in contentsOfDir) {
            NSString *extension = currentPath.pathExtension.lowercaseString;
            if (![mediaExtensions containsObject:extension]) {
                continue;
            }
            
            // If the file is not referenced in any post we can delete it
            NSString *filepath = [documentsDirectory stringByAppendingPathComponent:currentPath];
            
            if (![pathsToKeep containsObject:filepath]) {
                NSError *nukeError = nil;
                if ([[NSFileManager defaultManager] removeItemAtPath:filepath error:&nukeError] == NO) {
                    DDLogError(@"Error [%@] while nuking unused Media at path [%@]", nukeError.localizedDescription, filepath);
                }
            }
        }
    }];
}

@end
