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
#import "AccountService.h"
#import "WPImageSource.h"
#import "UIImage+Resize.h"
#import "WPBlogMediaCollectionViewController.h"

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

- (void)syncMediaLibraryForBlog:(Blog *)blog
                        success:(void (^)())success
                        failure:(void (^)(NSError *error))failure
{
    id<MediaServiceRemote> remote = [self remoteForBlog:blog];
    [remote getMediaLibraryForBlog:blog
                           success:^(NSArray *media) {
                               [self.managedObjectContext performBlock:^{
                                   [self mergeMedia:media forBlog:blog completionHandler:success];
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

- (void)mergeMedia:(NSArray *)media forBlog:(Blog *)blog completionHandler:(void (^)(void))completion
{
    NSMutableArray *mediaToKeep = [NSMutableArray array];
    for (RemoteMedia *remote in media) {
        Media *local = [self findMediaWithID:remote.mediaID inBlog:blog];
        if (!local) {
            local = [self newMediaForBlog:blog];
            local.remoteStatus = MediaRemoteStatusSync;
        }
        [self updateMedia:local withRemoteMedia:remote];
        [mediaToKeep addObject:local];
    }
    
    NSSet *existingMedia = blog.media;
    NSMutableOrderedSet *mediaToThumbnail = [NSMutableOrderedSet orderedSet];
    if (existingMedia.count > 0) {
        for (Media *existing in existingMedia) {
            if (![mediaToKeep containsObject:existing] && existing.remoteURL != nil) {
                [self.managedObjectContext deleteObject:existing];
            } else if (existing.remoteURL.length && !existing.thumbnail && existing.mediaType == MediaTypeImage) {
                [mediaToThumbnail addObject:existing];
            }
        }
    }
    
    [[ContextManager sharedInstance] saveDerivedContext:self.managedObjectContext];
    
    [mediaToThumbnail sortUsingComparator:^NSComparisonResult(Media *left, Media *right) {
        return [right.creationDate compare:left.creationDate];
    }];
    [self getThumbnailsForMedia:mediaToThumbnail];
    
    if (completion) {
        dispatch_async(dispatch_get_main_queue(), completion);
    }
}

- (void)getThumbnailsForMedia:(NSMutableOrderedSet *)media
{
    Media *item = nil;
    do {
        item = media.firstObject;
        [media removeObject:item];
        // might have updated it to show in browser since last sync
        [self.managedObjectContext refreshObject:item mergeChanges:YES];
        if (!item.remoteURL.length || item.thumbnail || item.mediaType != MediaTypeImage) {
            item = nil;
            continue;
        }
    } while (!item && [media count]);
    if (!item) {
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        [self getThumbnailForMedia:item
                           success:^(UIImage *image) {
                               [self performSelector:@selector(getThumbnailsForMedia:) withObject:media afterDelay:0.1];
                           }
                           failure:^(NSError *error) {
                               DDLogError(@"Failed getting thumbnail image: %@", error);
                           }];
    });
}

- (void)getThumbnailForMedia:(Media *)media
                     success:(void (^)(UIImage *image))success
                     failure:(void (^)(NSError *error))failure
{
    NSInteger thumbnailSize = round([WPBlogMediaCollectionViewController thumbnailWidthFor:[[UIScreen mainScreen] bounds].size.width]);
    __block NSURL *thumbnailUrl = nil;
    __block BOOL isPrivate = NO;
    [self.managedObjectContext performBlockAndWait:^{
        NSString *remote = media.remoteURL;
        if (media.blog.isWPcom) {
            remote = [NSString stringWithFormat:@"%@?w=%ld", remote, thumbnailSize];
        }
        thumbnailUrl = [NSURL URLWithString:remote];
        isPrivate = media.blog.isPrivate;
    }];
     
    void (^successBlock)(UIImage *) = ^(UIImage *image) {
        UIImage *thumbnail = image;
        if (thumbnail.size.width > thumbnailSize || thumbnail.size.height > thumbnailSize) {
            thumbnail = [image thumbnailImage:thumbnailSize transparentBorder:0 cornerRadius:0 interpolationQuality:0.9];
        }
        NSData *thumbnailData = UIImageJPEGRepresentation(thumbnail, 0.9);

        [self.managedObjectContext performBlock:^{
            media.thumbnail = thumbnailData;
            [[ContextManager sharedInstance] saveDerivedContext:self.managedObjectContext withCompletionBlock:^{
                if (success) {
                    success(thumbnail);
                }
            }];
        }];
    };

    if (isPrivate) {
        __block NSString *authToken = nil;
        [self.managedObjectContext performBlockAndWait:^{
            AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:self.managedObjectContext];
            authToken = [[[accountService defaultWordPressComAccount] restApi] authToken];
        }];
        [[WPImageSource sharedSource] downloadImageForURL:thumbnailUrl
                                                authToken:authToken
                                              withSuccess:successBlock
                                                  failure:failure];
    } else {
        [[WPImageSource sharedSource] downloadImageForURL:thumbnailUrl
                                              withSuccess:successBlock
                                                  failure:failure];
    }
}

- (void)createMediaWithAsset:(ALAsset *)asset
             forPostObjectID:(NSManagedObjectID *)postObjectID
                  completion:(void (^)(Media *media, NSError * error))completion
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

    geoLocationEnabled = post.blog.geolocationEnabled;
    
    CGSize maxImageSize = [MediaService maxImageSizeSetting];
    NSString *imagePath = [self pathForAsset:asset];
    
    [[WPAssetExporter sharedInstance] exportAsset:asset
                                           toFile:imagePath
                                         resizing:maxImageSize
                                 stripGeoLocation:!geoLocationEnabled
                                completionHandler:^(BOOL success, CGSize resultingSize, NSData * thumbnailData, NSError *error) {
        if (!success) {
            if (completion){
                completion(nil, error);
            }
            return;
        }
        [self.managedObjectContext performBlock:^{
            
            AbstractPost *post = (AbstractPost *)[self.managedObjectContext objectWithID:postObjectID];
            Media *media = [self newMediaForPost:post];
            media.filename = [imagePath lastPathComponent];
            media.localURL = imagePath;
            media.thumbnail = thumbnailData;
            NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:imagePath error:nil];
            // This is kind of lame, but we've been storing file size as KB so far
            // We should store size in bytes or rename the property to avoid confusion
            media.filesize = @([fileAttributes fileSize] / 1024);
            media.width = @(resultingSize.width);
            media.height = @(resultingSize.height);
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

- (NSString *)pathForAsset:(ALAsset *)asset
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths[0];
    NSString *filename = asset.defaultRepresentation.filename;
    NSString *path = [documentsDirectory stringByAppendingPathComponent:filename];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSUInteger index = 0;
    while ([fileManager fileExistsAtPath:path]) {
        NSString *basename = [filename stringByDeletingPathExtension];
        NSString *extension = [filename pathExtension];
        NSString *alternativeFilename = [NSString stringWithFormat:@"%@-%d.%@", basename, index, extension];
        path = [documentsDirectory stringByAppendingPathComponent:alternativeFilename];
        index++;
    }
    return path;
}

- (NSString *)mimeTypeForFilename:(NSString *)filename
{
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
    media.filename = remoteMedia.file;
    [media mediaTypeFromUrl:[remoteMedia extension]];
    // these aren't maintained during upload
    if ([remoteMedia.title isKindOfClass:[NSString class]]) {
        media.title = remoteMedia.title;
    }
    if ([remoteMedia.caption isKindOfClass:[NSString class]]) {
        media.caption = remoteMedia.caption;
    }
    if ([remoteMedia.date isKindOfClass:[NSDate class]]) {
        media.creationDate = remoteMedia.date;
    }
    if ([remoteMedia.descriptionText isKindOfClass:[NSString class]]) {
        media.desc = remoteMedia.descriptionText;
    }
    if ([remoteMedia.height isKindOfClass:[NSNumber class]]) {
        media.height = remoteMedia.height;
    }
    if ([remoteMedia.width isKindOfClass:[NSNumber class]]) {
        media.width = remoteMedia.width;
    }
}

- (RemoteMedia *)remoteMediaFromMedia:(Media *)media
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

@end
