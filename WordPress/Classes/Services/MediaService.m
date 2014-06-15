#import "MediaService.h"
#import "Media.h"
#import "WPAccount.h"
#import "WPImageOptimizer.h"
#import "ContextManager.h"
#import "MediaServiceRemoteXMLRPC.h"
#import "MediaServiceRemoteREST.h"
#import "WPVideoOptimizer.h"

#import <MobileCoreServices/MobileCoreServices.h>


@interface MediaService ()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

@implementation MediaService

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context {
    self = [super init];
    if (self) {
        _managedObjectContext = context;
    }

    return self;
}

- (void)createMediaWithAsset:(ALAsset *)asset forPostObjectID:(NSManagedObjectID *)postObjectID completion:(void (^)(Media *media))completion {

    WPImageOptimizer *optimizer = [WPImageOptimizer new];
    NSData * optimizedData = [optimizer optimizedDataFromAsset:asset];
    NSData *thumbnailData = [self thumbnailDataFromAsset:asset];
    NSString *imagePath = [self pathForAsset:asset];
    if (![self writeData:optimizedData toPath:imagePath]) {
        DDLogError(@"Error writing media to %@", imagePath);
    }
    [self.managedObjectContext performBlock:^{
        AbstractPost *post = (AbstractPost *)[self.managedObjectContext objectWithID:postObjectID];
        Media *media = [self newMediaForPost:post];
        media.filename = [imagePath lastPathComponent];
        media.localURL = imagePath;
        media.thumbnail = thumbnailData;
        // This is kind of lame, but we've been storing file size as KB so far
        // We should store size in bytes or rename the property to avoid confusion
        media.filesize = @(optimizedData.length / 1024);
        media.width = @(asset.defaultRepresentation.dimensions.width);
        media.height = @(asset.defaultRepresentation.dimensions.height);
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
        if (completion) {
            completion(media);
        }
    }];
}

- (void)createVideoMediaWithAsset:(ALAsset *)asset forPostObjectID:(NSManagedObjectID *)postObjectID completion:(void (^)(Media *media))completion
{
    NSString *videoPath = [self pathForAsset:asset];
    NSData *thumbnailData = [self thumbnailDataFromAsset:asset];
    __block Media *media = nil;
    [self.managedObjectContext performBlockAndWait:^{
        AbstractPost *post = (AbstractPost *)[self.managedObjectContext objectWithID:postObjectID];
        media = [self newMediaForPost:post];
        media.filename = [videoPath lastPathComponent];
        media.localURL = videoPath;
        media.thumbnail = thumbnailData;
        media.mediaType = MediaTypeVideo;
        media.remoteStatus = MediaRemoteStatusProcessing;
        [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
    }];
    
    WPVideoOptimizer *optimizer = [[WPVideoOptimizer alloc] init];
    [optimizer optimizeAsset:asset toPath:videoPath withHandler:^(NSError *error) {
        if (error){
            DDLogError(@"Error writing media to %@", videoPath);
            [media remove];            
            return;
        }
        [self.managedObjectContext performBlock:^{
            //AbstractPost *post = (AbstractPost *)[self.managedObjectContext objectWithID:postObjectID];
            //Media *media = [self newMediaForPost:post];
            media.filename = [videoPath lastPathComponent];
            media.localURL = videoPath;
            media.thumbnail = thumbnailData;
            media.mediaType = MediaTypeVideo;
            // This is kind of lame, but we've been storing file size as KB so far
            // We should store size in bytes or rename the property to avoid confusion
            NSDictionary * fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:videoPath error:nil];
            media.filesize = @([fileAttributes fileSize] / 1024);
            media.width = @(asset.defaultRepresentation.dimensions.width);
            media.height = @(asset.defaultRepresentation.dimensions.height);
            [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
            if (completion) {
                completion(media);
            }
        }];
    }];
}

- (AFHTTPRequestOperation *)operationToUploadMedia:(Media *)media withSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    media.remoteStatus = MediaRemoteStatusPushing;
    NSString * mediaType = [self mimeTypeForFilename:media.filename];
    BOOL isVideo = [self isFileVideo:media.filename];
    id<MediaServiceRemote> remote = [self remoteForBlog:media.blog forceRPC:(isVideo && media.blog.isWPcom)];
    return [remote operationToUploadFile:media.localURL
                                  ofType:mediaType
                            withFilename:media.filename
                                  toBlog:media.blog
                                 success:^(NSNumber *mediaID, NSString *url, NSString * shortCode) {
                                     [self.managedObjectContext performBlock:^{
                                         media.remoteStatus = MediaRemoteStatusSync;
                                         media.mediaID = mediaID;
                                         media.remoteURL = url;
                                         media.shortcode = shortCode;
                                         [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
                                         if (success) {
                                             success();
                                         }
                                     }];
                                 } failure:^(NSError *error) {
                                     [self.managedObjectContext performBlock:^{
                                         media.remoteStatus = MediaRemoteStatusFailed;
                                         if (failure) {
                                             failure(error);
                                         }
                                     }];
                                 }];
}

#pragma mark - Private

#pragma mark - Media Creation

- (Media *)newMedia {
    Media *media = [NSEntityDescription insertNewObjectForEntityForName:@"Media" inManagedObjectContext:self.managedObjectContext];
    media.creationDate = [NSDate date];
    media.mediaID = @0;
    // We only support images for now, so let's set the default here
    media.mediaType = MediaTypeImage;
    return media;
}

- (Media *)newMediaForBlog:(Blog *)blog {
    Media *media = [self newMedia];
    media.blog = blog;
    return media;
}

- (Media *)newMediaForPost:(AbstractPost *)post {
    Media *media = [self newMediaForBlog:post.blog];
    [media.posts addObject:post];
    return media;
}

#pragma mark - Media helpers

- (NSString *)pathForAsset:(ALAsset *)asset {
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

- (BOOL)writeData:(NSData *)data toPath:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager createFileAtPath:path contents:data attributes:@{NSFileProtectionKey: NSFileProtectionComplete}];
}

- (NSData *)thumbnailDataFromAsset:(ALAsset *)asset {
    UIImage *thumbnail = [UIImage imageWithCGImage:asset.thumbnail];
    NSData *thumbnailJPEGData = UIImageJPEGRepresentation(thumbnail, 1.0);
    return thumbnailJPEGData;
}

- (NSString *)mimeTypeForFilename:(NSString *)filename {
    // Get the UTI from the file's extension:
    CFStringRef pathExtension = (__bridge_retained CFStringRef)[filename pathExtension];
    CFStringRef type = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, NULL);
    CFRelease(pathExtension);

    // The UTI can be converted to a mime type:
    NSString *mimeType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass(type, kUTTagClassMIMEType);
    if (type != NULL)
        CFRelease(type);

    return mimeType;
}

- (BOOL) isFileVideo:(NSString *) filename{
    CFStringRef pathExtension = (__bridge_retained CFStringRef)[filename pathExtension];
    CFStringRef type = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, NULL);

    return UTTypeConformsTo(type, kUTTypeMovie) ? YES:NO;
}

- (id<MediaServiceRemote>)remoteForBlog:(Blog *)blog forceRPC:(BOOL) forceRPC{
    id <MediaServiceRemote> remote;
    if (blog.restApi && !forceRPC) {
        remote = [[MediaServiceRemoteREST alloc] initWithApi:blog.restApi];
    } else {
        WPXMLRPCClient *client = [WPXMLRPCClient clientWithXMLRPCEndpoint:[NSURL URLWithString:blog.xmlrpc]];
        remote = [[MediaServiceRemoteXMLRPC alloc] initWithApi:client];
    }
    return remote;
}
@end
