#import "MediaService.h"
#import "AccountService.h"
#import "Media.h"
#import "WPAccount.h"
#import "WPImageOptimizer.h"
#import "ContextManager.h"
#import "MediaServiceRemoteXMLRPC.h"
#import "MediaServiceRemoteREST.h"
#import "Blog.h"
#import "RemoteMedia.h"
#import "WPAssetExporter.h"
#import "WPImageSource.h"
#import "UIImage+Resize.h"
#import <MobileCoreServices/MobileCoreServices.h>

NSString * const SavedMaxImageSizeSetting = @"SavedMaxImageSizeSetting";
CGSize const MediaMaxImageSize = {3000, 3000};
NSInteger const MediaMinImageSizeDimension = 150;
NSInteger const MediaMaxImageSizeDimension = 3000;

@implementation MediaService

+ (CGSize)maxImageSizeSetting
{
    NSString *savedSize = [[NSUserDefaults standardUserDefaults] stringForKey:SavedMaxImageSizeSetting];
    CGSize maxSize = MediaMaxImageSize;
    if (savedSize) {
        maxSize = CGSizeFromString(savedSize);
    }
    return maxSize;
}

+ (void)setMaxImageSizeSetting:(CGSize)imageSize
{
    // Constraint to max width and height.
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    width = MAX(MIN(width, MediaMaxImageSizeDimension), MediaMinImageSizeDimension);
    height = MAX(MIN(height, MediaMaxImageSizeDimension), MediaMinImageSizeDimension);

    NSString *strSize = NSStringFromCGSize(CGSizeMake(width, height));
    [[NSUserDefaults standardUserDefaults] setObject:strSize forKey:SavedMaxImageSizeSetting];
    [NSUserDefaults resetStandardUserDefaults];
}

- (void)createMediaWithAsset:(ALAsset *)asset
             forPostObjectID:(NSManagedObjectID *)postObjectID
                  completion:(void (^)(Media *media, NSError *error))completion
{
    BOOL geoLocationEnabled = NO;
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
    if ([[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]) {
        mediaType = MediaTypeImage;
        allowedFileTypes = post.blog.allowedFileTypes;
    } else if ([[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]) {
        // We ignore allowsFileTypes for videos because if videopress is not enabled we still can upload
        // files even if the allowed file types says no.
        allowedFileTypes = nil;
        mediaType = MediaTypeVideo;
    }

    geoLocationEnabled = post.blog.geolocationEnabled;

    CGSize maxImageSize = [MediaService maxImageSizeSetting];
    
    NSString *mediaPath = [self pathForAsset:asset supportedFileFormats:allowedFileTypes];

    [[WPAssetExporter sharedInstance] exportAsset:asset
                                           toFile:mediaPath
                                         resizing:maxImageSize
                                 stripGeoLocation:!geoLocationEnabled
                                completionHandler:^(BOOL success, CGSize resultingSize, NSData *thumbnailData, NSError *error) {
        if (!success) {
            if (completion){
                completion(nil, error);
            }
            return;
        }
        [self.managedObjectContext performBlock:^{
            
            AbstractPost *post = (AbstractPost *)[self.managedObjectContext objectWithID:postObjectID];
            Media *media = [self newMediaForPost:post];
            media.filename = [mediaPath lastPathComponent];
            media.absoluteLocalURL = mediaPath;
            media.absoluteThumbnailLocalURL = [self pathForThumbnailOfFile:mediaPath];
            [thumbnailData writeToFile:media.absoluteThumbnailLocalURL atomically:NO];
            NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:mediaPath error:nil];
            // This is kind of lame, but we've been storing file size as KB so far
            // We should store size in bytes or rename the property to avoid confusion
            media.filesize = @([fileAttributes fileSize] / 1024);
            media.width = @(resultingSize.width);
            media.height = @(resultingSize.height);
            media.mediaType = mediaType;
            //make sure that we only return when object is properly created and saved
            [[ContextManager sharedInstance] saveContext:self.managedObjectContext withCompletionBlock:^{
                if (completion) {
                    completion(media, nil);
                }
            }];
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
                failure(error);
            }
        }];
    };
    
    [remote createMedia:remoteMedia
                forBlog:media.blog
               progress:progress
                success:successBlock
                failure:failureBlock];
}

- (void) getMediaWithID:(NSNumber *) mediaID inBlog:(Blog *) blog
            withSuccess:(void (^)(Media *media))success
                failure:(void (^)(NSError *error))failure
{
    id<MediaServiceRemote> remote = [self remoteForBlog:blog];
    NSManagedObjectID *blogID = blog.objectID;
    
    [remote getMediaWithID:mediaID forBlog:blog success:^(RemoteMedia *remoteMedia) {
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
    [remote getMediaLibraryForBlog:blog
                           success:^(NSArray *media) {
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
                NSString *filePath = [self pathForFilename:[self pathForThumbnailOfFile:media.filename] supportedFileFormats:nil];
                media.absoluteThumbnailLocalURL = filePath;            
                [self.managedObjectContext save:nil];
                [[[self class] queueForResizeMediaOperations] addOperationWithBlock:^{                    
                    NSData *data = UIImagePNGRepresentation(image);
                    [data writeToFile:filePath atomically:YES];
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
    [remote getMediaLibraryCountForBlog:blog
                           success:^(NSInteger count) {
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
    [media.posts addObject:post];
    return media;
}

#pragma mark - Media helpers

static NSString * const MediaDirectory = @"Media";

- (NSString *)pathForAsset:(ALAsset *)asset supportedFileFormats:(NSSet *)supportedFileFormats
{
    NSString *filename = asset.defaultRepresentation.filename;
    return [self pathForFilename:filename supportedFileFormats:supportedFileFormats];

}
- (NSString *)pathForFilename:(NSString *)filename supportedFileFormats:(NSSet *)supportedFileFormats
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *mediaDirectory = [documentsDirectory stringByAppendingPathComponent:MediaDirectory];
    BOOL isDirectory;
    NSError *error;
    if (![fileManager fileExistsAtPath:mediaDirectory isDirectory:&isDirectory] || !isDirectory){
        if ([fileManager createDirectoryAtPath:mediaDirectory withIntermediateDirectories:YES attributes:nil error:&error]){
            [[NSURL fileURLWithPath:mediaDirectory] setResourceValue:@(NO) forKey:NSURLIsExcludedFromBackupKey error:nil];
        } else {
            DDLogError(@"%@", [error localizedDescription]);
        }
    }
    NSString *path = [mediaDirectory stringByAppendingPathComponent:filename];
    NSString *basename = [filename stringByDeletingPathExtension];
    NSString *extension = [[filename pathExtension] lowercaseString];
    if (supportedFileFormats && ![supportedFileFormats containsObject:extension]){
        extension = @"png";
        filename = [NSString stringWithFormat:@"%@.%@", basename, extension];
        path = [mediaDirectory stringByAppendingPathComponent:filename];
    }
    NSUInteger index = 0;
    while ([fileManager fileExistsAtPath:path]) {
        NSString *alternativeFilename = [NSString stringWithFormat:@"%@-%d.%@", basename, index, extension];
        path = [mediaDirectory stringByAppendingPathComponent:alternativeFilename];
        index++;
    }
    return path;
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
        remote = [[MediaServiceRemoteREST alloc] initWithApi:blog.restApi];
    } else {
        WPXMLRPCClient *client = [WPXMLRPCClient clientWithXMLRPCEndpoint:[NSURL URLWithString:blog.xmlrpc]];
        remote = [[MediaServiceRemoteXMLRPC alloc] initWithApi:client];
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
    remoteMedia.mimeType = [self mimeTypeForFilename:media.filename];
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
