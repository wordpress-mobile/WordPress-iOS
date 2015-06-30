#import "MediaService.h"
#import "Media.h"
#import "WPAccount.h"
#import "WPImageOptimizer.h"
#import "ContextManager.h"
#import "MediaServiceRemoteXMLRPC.h"
#import "MediaServiceRemoteREST.h"
#import "Blog.h"
#import "RemoteMedia.h"
#import "WPAssetExporter.h"
#import <MobileCoreServices/MobileCoreServices.h>

NSString * const SavedMaxImageSizeSetting = @"SavedMaxImageSizeSetting";
CGSize const MediaMaxImageSize = {3000, 3000};
NSInteger const MediaMinImageSizeDimension = 150;
NSInteger const MediaMaxImageSizeDimension = 3000;

@interface MediaService ()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

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

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context
{
    self = [super init];
    if (self) {
        _managedObjectContext = context;
    }

    return self;
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
            media.localURL = mediaPath;
            media.thumbnail = thumbnailData;
            [thumbnailData writeToFile:media.thumbnailLocalURL atomically:NO];
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
    
    [remote getMediaWithID:mediaID forBlog:blog success:^(RemoteMedia *remoteMedia) {
       [self.managedObjectContext performBlock:^{
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
    NSSet *mediaSet = [blog.media filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"shortcode = %@", videoPressID]];
    Media *media = [mediaSet anyObject];
    if (media) {
        if([[NSFileManager defaultManager] fileExistsAtPath:media.thumbnailLocalURL isDirectory:nil]) {
            success(media.remoteURL, media.thumbnailLocalURL);
        } else {
            success(media.remoteURL, @"");
        }
    } else {
        failure(nil);
    }
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

- (NSString *)pathForAsset:(ALAsset *)asset supportedFileFormats:(NSSet *)supportedFileFormats
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths[0];
    NSString *filename = asset.defaultRepresentation.filename;
    NSString *path = [documentsDirectory stringByAppendingPathComponent:filename];
    NSString *basename = [filename stringByDeletingPathExtension];
    NSString *extension = [[filename pathExtension] lowercaseString];
    if (supportedFileFormats && ![supportedFileFormats containsObject:extension]){
        extension = @"png";
        filename = [NSString stringWithFormat:@"%@.%@", basename, extension];
        path = [documentsDirectory stringByAppendingPathComponent:filename];
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSUInteger index = 0;
    while ([fileManager fileExistsAtPath:path]) {
        NSString *alternativeFilename = [NSString stringWithFormat:@"%@-%d.%@", basename, index, extension];
        path = [documentsDirectory stringByAppendingPathComponent:alternativeFilename];
        index++;
    }
    return path;
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
    //media.exif = remoteMedia.exif;
    media.shortcode = remoteMedia.shortcode;
}

- (RemoteMedia *) remoteMediaFromMedia:(Media *)media
{
    RemoteMedia *remoteMedia = [[RemoteMedia alloc] init];
    remoteMedia.mediaID = media.mediaID;
    remoteMedia.url = [NSURL URLWithString:media.remoteURL];
    remoteMedia.date = media.creationDate;
    remoteMedia.file = media.filename;
    remoteMedia.extension = media.mediaTypeString;
    remoteMedia.title = media.title;
    remoteMedia.caption = media.caption;
    remoteMedia.descriptionText = media.desc;
    remoteMedia.height = media.height;
    remoteMedia.width = media.width;
    remoteMedia.localURL = media.localURL;
    remoteMedia.mimeType = [self mimeTypeForFilename:media.filename];    
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
