#import "Media.h"
#import "ContextManager.h"

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

- (NSString *)absoluteThumbnailLocalURL;
{
    if ( self.localThumbnailURL ) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths firstObject];
        NSString *absolutePath = [NSString pathWithComponents:@[documentsDirectory, self.localThumbnailURL]];
        return absolutePath;
    } else {
        return nil;
    }
}

- (void)setAbsoluteThumbnailLocalURL:(NSString *)absoluteLocalURL
{
    NSParameterAssert([absoluteLocalURL isAbsolutePath]);
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *localPath =  [absoluteLocalURL stringByReplacingOccurrencesOfString:documentsDirectory withString:@""];
    self.localThumbnailURL = localPath;
}

- (NSString *)absoluteLocalURL
{
    if ( self.localURL ) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths firstObject];
        NSString *absolutePath = [NSString pathWithComponents:@[documentsDirectory, self.localURL]];
        return absolutePath;
    } else {
        return nil;
    }
}

- (void)setAbsoluteLocalURL:(NSString *)absoluteLocalURL
{
    NSParameterAssert([absoluteLocalURL isAbsolutePath]);
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *localPath =  [absoluteLocalURL stringByReplacingOccurrencesOfString:documentsDirectory withString:@""];
    self.localURL = localPath;
}

#pragma mark - CoreData Helpers

- (void)prepareForDeletion
{
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:self.absoluteLocalURL] &&
        ![fileManager removeItemAtPath:self.absoluteLocalURL error:&error]) {
        DDLogInfo(@"Error removing media files:%@", error);
    }
    if ([fileManager fileExistsAtPath:self.absoluteThumbnailLocalURL] &&
        ![fileManager removeItemAtPath:self.absoluteThumbnailLocalURL error:&error]) {
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

@end
