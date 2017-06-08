#import "Media.h"
#import "ContextManager.h"
#import "WordPress-Swift.h"

@implementation Media

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
@dynamic localThumbnailURL;
@dynamic remoteThumbnailURL;
@dynamic postID;

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
    CFStringRef ppt = (__bridge CFStringRef)@"public.presentation";
    MediaType type;
    if (UTTypeConformsTo(fileUTI, kUTTypeImage)) {
        type = MediaTypeImage;
    } else if (UTTypeConformsTo(fileUTI, kUTTypeVideo)) {
        type = MediaTypeVideo;
    } else if (UTTypeConformsTo(fileUTI, kUTTypeMovie)) {
        type = MediaTypeVideo;
    } else if (UTTypeConformsTo(fileUTI, kUTTypeMPEG4)) {
        type = MediaTypeVideo;
    } else if (UTTypeConformsTo(fileUTI, ppt)) {
        type = MediaTypePowerpoint;
    } else if (UTTypeConformsTo(fileUTI, kUTTypeAudio)) {
        type = MediaTypeAudio;
    } else {
        type = MediaTypeDocument;
    }
    if (fileUTI) {
        CFRelease(fileUTI);
        fileUTI = nil;
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
    [self setRemoteStatusNumber:[NSNumber numberWithInt:aStatus]];
}

- (NSString *)remoteStatusText
{
    switch ([self.remoteStatusNumber intValue]) {
        case MediaRemoteStatusPushing:
            return NSLocalizedString(@"Uploading", @"");
        case MediaRemoteStatusFailed:
            return NSLocalizedString(@"Failed", @"");
        case MediaRemoteStatusSync:
            return NSLocalizedString(@"Uploaded", @"");
        default:
            return NSLocalizedString(@"Pending", @"");
    }
}

#pragma mark - Absolute URLs

- (NSURL *)absoluteThumbnailLocalURL;
{
    if (!self.localThumbnailURL.length) {
        return nil;
    }
    return [self absoluteURLForLocalPath:self.localThumbnailURL];
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
    return [self absoluteURLForLocalPath:self.localURL];
}

- (void)setAbsoluteLocalURL:(NSURL *)absoluteLocalURL
{
    self.localURL = absoluteLocalURL.lastPathComponent;
}

- (NSURL *)absoluteURLForLocalPath:(NSString *)localPath
{
    NSError *error;
    NSURL *mediaDirectory = [MediaLibrary localUploadsDirectoryAndReturnError:&error];
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
