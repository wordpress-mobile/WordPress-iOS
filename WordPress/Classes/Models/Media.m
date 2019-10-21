#import "Media.h"
#import "ContextManager.h"
#import "WordPress-Swift.h"

@implementation Media

@dynamic alt;
@dynamic mediaID;
@dynamic remoteURL;
@dynamic localURL;
@dynamic shortcode;
@dynamic width;
@dynamic length;
@dynamic title;
@dynamic height;
@dynamic filename;
@dynamic filesize;
@dynamic creationDate;
@dynamic blog;
@dynamic posts;
@dynamic remoteStatusNumber;
@dynamic caption;
@dynamic desc;
@dynamic mediaTypeString;
@dynamic videopressGUID;
@dynamic localThumbnailIdentifier;
@dynamic localThumbnailURL;
@dynamic remoteThumbnailURL;
@dynamic postID;
@dynamic error;
@dynamic featuredOnPosts;
@dynamic autoUploadFailureCount;

#pragma mark -

+ (NSString *)stringFromMediaType:(MediaType)mediaType
{
    switch (mediaType) {
        case MediaTypeImage:
            return @"image";
            break;
        case MediaTypeVideo:
            return @"video";
            break;
        case MediaTypePowerpoint:
            return @"powerpoint";
            break;
        case MediaTypeDocument:
            return @"document";
            break;
        case MediaTypeAudio:
            return @"audio";
            break;
    }
}

#pragma mark -

- (NSString *)fileExtension
{
    NSString *extension = [self.filename pathExtension];
    if (extension.length) {
        return extension;
    }
    extension = [self.localURL pathExtension];
    if (extension.length) {
        return extension;
    }
    extension = [self.remoteURL pathExtension];
    return extension;
}

- (NSString *)mimeType
{
    NSString *unknown = @"application/octet-stream";
    NSString *extension = [self fileExtension];
    if (!extension.length) {
        return unknown;
    }
    NSString *fileUTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
    NSString *mimeType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)fileUTI, kUTTagClassMIMEType);
    if (!mimeType) {
        return unknown;
    } else {
        return mimeType;
    }
}

#pragma mark - Media Types

- (MediaType)mediaType
{
    if ([self.mediaTypeString isEqualToString:[Media stringFromMediaType:MediaTypeImage]]) {
        return MediaTypeImage;
    } else if ([self.mediaTypeString isEqualToString:[Media stringFromMediaType:MediaTypeVideo]]) {
        return MediaTypeVideo;
    } else if ([self.mediaTypeString isEqualToString:[Media stringFromMediaType:MediaTypePowerpoint]]) {
        return MediaTypePowerpoint;
    } else if ([self.mediaTypeString isEqualToString:[Media stringFromMediaType:MediaTypeDocument]]) {
        return MediaTypeDocument;
    } else if ([self.mediaTypeString isEqualToString:[Media stringFromMediaType:MediaTypeAudio]]) {
        return MediaTypeAudio;
    }

    return MediaTypeDocument;
}

- (void)setMediaType:(MediaType)mediaType
{
    self.mediaTypeString = [[self class] stringFromMediaType:mediaType];    
}

- (void)setMediaTypeForExtension:(NSString *)extension
{
    CFStringRef fileExt = (__bridge CFStringRef)extension;
    CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExt, nil);
    [self setMediaTypeForUTI:CFBridgingRelease(fileUTI)];
}

- (void)setMediaTypeForMimeType:(NSString *)mimeType
{
    NSString *filteredMimeType = mimeType;
    if ( [filteredMimeType isEqual:@"video/videopress"]) {
        filteredMimeType = @"video/mp4";
    }
    CFStringRef fileType = (__bridge CFStringRef)filteredMimeType;
    CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, fileType, nil);
    [self setMediaTypeForUTI:CFBridgingRelease(fileUTI)];
}


- (void)setMediaTypeForUTI:(NSString *)uti
{
    CFStringRef fileUTI = (__bridge CFStringRef _Nonnull)(uti);
    MediaType type;
    if (UTTypeConformsTo(fileUTI, kUTTypeImage)) {
        type = MediaTypeImage;
    } else if (UTTypeConformsTo(fileUTI, kUTTypeVideo)) {
        type = MediaTypeVideo;
    } else if (UTTypeConformsTo(fileUTI, kUTTypeMovie)) {
        type = MediaTypeVideo;
    } else if (UTTypeConformsTo(fileUTI, kUTTypeMPEG4)) {
        type = MediaTypeVideo;
    } else if (UTTypeConformsTo(fileUTI, kUTTypePresentation)) {
        type = MediaTypePowerpoint;
    } else if (UTTypeConformsTo(fileUTI, kUTTypeAudio)) {
        type = MediaTypeAudio;
    } else {
        type = MediaTypeDocument;
    }    
    self.mediaType = type;
}

#pragma mark - Remote Status

- (MediaRemoteStatus)remoteStatus
{
    return (MediaRemoteStatus)[[self remoteStatusNumber] intValue];
}

- (void)setRemoteStatus:(MediaRemoteStatus)aStatus
{
    [self setRemoteStatusNumber:@(aStatus)];
}

- (NSString *)remoteStatusText
{
    switch (self.remoteStatus) {
        case MediaRemoteStatusPushing:
            return NSLocalizedString(@"Uploading", @"Status for Media object that is being uploaded.");
        case MediaRemoteStatusFailed:
            return NSLocalizedString(@"Failed", @"Status for Media object that is failed upload or export.");
        case MediaRemoteStatusSync:
            return NSLocalizedString(@"Uploaded", @"Status for Media object that is uploaded and sync with server.");
        case MediaRemoteStatusProcessing:
            return NSLocalizedString(@"Pending", @"Status for Media object that is being processed locally.");
        case MediaRemoteStatusLocal:
            return NSLocalizedString(@"Local", @"Status for Media object that is only exists locally.");
        case MediaRemoteStatusStub:
            return NSLocalizedString(@"Stub", @"Status for Media object that is only has the mediaID locally.");
    }
}

#pragma mark - Absolute URLs

- (NSURL *)absoluteThumbnailLocalURL;
{
    if (!self.localThumbnailURL.length) {
        return nil;
    }
    return [self absoluteURLForLocalPath:self.localThumbnailURL cacheDirectory:YES];
}

- (void)setAbsoluteThumbnailLocalURL:(NSURL *)absoluteLocalURL
{
    self.localThumbnailURL = absoluteLocalURL.lastPathComponent;
}

- (NSURL *)absoluteLocalURL
{
    if (!self.localURL.length) {
        return nil;
    }
    return [self absoluteURLForLocalPath:self.localURL cacheDirectory:NO];
}

- (void)setAbsoluteLocalURL:(NSURL *)absoluteLocalURL
{
    self.localURL = absoluteLocalURL.lastPathComponent;
}

- (NSURL *)absoluteURLForLocalPath:(NSString *)localPath cacheDirectory:(BOOL)cacheDirectory
{
    NSError *error;
    NSURL *mediaDirectory = nil;
    if (cacheDirectory) {
        mediaDirectory = [[MediaFileManager cacheManager] directoryURLAndReturnError:&error];
    } else {
        mediaDirectory = [MediaFileManager uploadsDirectoryURLAndReturnError:&error];
    }
    if (error) {
        DDLogInfo(@"Error resolving Media directory: %@", error);
        return nil;
    }
    return [mediaDirectory URLByAppendingPathComponent:localPath.lastPathComponent];
}

#pragma mark - CoreData Helpers

- (void)prepareForDeletion
{
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *absolutePath = self.absoluteLocalURL.path;
    if ([fileManager fileExistsAtPath:absolutePath] &&
        ![fileManager removeItemAtPath:absolutePath error:&error]) {
        DDLogInfo(@"Error removing media files:%@", error);
    }
    NSString *absoluteThumbnailPath = self.absoluteThumbnailLocalURL.path;
    if ([fileManager fileExistsAtPath:absoluteThumbnailPath] &&
        ![fileManager removeItemAtPath:absoluteThumbnailPath error:&error]) {
        DDLogInfo(@"Error removing media files:%@", error);
    }
    [super prepareForDeletion];
}

- (void)remove
{
    [self.managedObjectContext performBlockAndWait:^{
        [self.managedObjectContext deleteObject:self];
        [[ContextManager sharedInstance] saveContextAndWait:self.managedObjectContext];
    }];
}

- (void)save
{
    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
}

- (BOOL)hasRemote {
    return self.mediaID.intValue != 0;
}

@end
