#import "Media.h"

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
@dynamic orientation;
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

@synthesize unattached;

- (void)mediaTypeFromUrl:(NSString *)ext
{
    CFStringRef fileExt = (__bridge CFStringRef)ext;
    CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExt, nil);
    CFStringRef ppt = (__bridge CFStringRef)@"public.presentation";

    if (UTTypeConformsTo(fileUTI, kUTTypeImage)) {
        self.mediaTypeString = @"image";
    } else if (UTTypeConformsTo(fileUTI, kUTTypeVideo)) {
        self.mediaTypeString = @"video";
    } else if (UTTypeConformsTo(fileUTI, kUTTypeMovie)) {
        self.mediaTypeString = @"video";
    } else if (UTTypeConformsTo(fileUTI, kUTTypeMPEG4)) {
        self.mediaTypeString = @"video";
    } else if (UTTypeConformsTo(fileUTI, ppt)) {
        self.mediaTypeString = @"powerpoint";
    } else {
        self.mediaTypeString = @"document";
    }

    if (fileUTI) {
        CFRelease(fileUTI);
        fileUTI = nil;
    }
}

- (MediaType)mediaType
{
    if ([self.mediaTypeString isEqualToString:@"image"]) {
        return MediaTypeImage;
    } else if ([self.mediaTypeString isEqualToString:@"video"]) {
        return MediaTypeVideo;
    } else if ([self.mediaTypeString isEqualToString:@"powerpoint"]) {
        return MediaTypePowerpoint;
    } else if ([self.mediaTypeString isEqualToString:@"document"]) {
        return MediaTypeDocument;
    } else if ([self.mediaTypeString isEqualToString:@"featured"]) {
        // this is for object that where still storing the old value.
        return MediaTypeImage;
    }
    return MediaTypeDocument;
}

- (void)setMediaType:(MediaType)mediaType
{
    self.mediaTypeString = [[self class] stringFromMediaType:mediaType];    
}

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

- (BOOL)featured
{
    for (AbstractPost *post in self.posts) {
        if ([post.post_thumbnail isEqualToNumber:self.mediaID]){
            return YES;
        }
    }
    return NO;
}


#pragma mark -

- (MediaRemoteStatus)remoteStatus
{
    return (MediaRemoteStatus)[[self remoteStatusNumber] intValue];
}

- (void)setRemoteStatus:(MediaRemoteStatus)aStatus
{
    [self setRemoteStatusNumber:[NSNumber numberWithInt:aStatus]];
}

+ (NSString *)titleForRemoteStatus:(NSNumber *)remoteStatus
{
    switch ([remoteStatus intValue]) {
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

- (NSString *)remoteStatusText
{
    return [Media titleForRemoteStatus:self.remoteStatusNumber];
}

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
        [self.managedObjectContext save:nil];
    }];
}

- (void)save
{
    [self.managedObjectContext performBlock:^{
        [self.managedObjectContext save:nil];
    }];
}

- (BOOL)unattached
{
    return self.posts.count == 0;
}

- (NSString *)html
{
    NSString *result = @"";
    if (self.mediaType == MediaTypeImage) {
        if (self.shortcode != nil) {
            result = self.shortcode;
        } else if (self.remoteURL != nil) {
            NSString *linkType = nil;
            if ( [[self.blog getOptionValue:@"image_default_link_type"] isKindOfClass:[NSString class]] ) {
                linkType = (NSString *)[self.blog getOptionValue:@"image_default_link_type"];
            } else {
                linkType = @"";
            }

            if ([linkType isEqualToString:@"none"]) {
                result = [NSString stringWithFormat:
                          @"<img src=\"%@\" alt=\"%@\" class=\"alignnone size-full\" />",
                          self.remoteURL, self.title];
            } else {
                result = [NSString stringWithFormat:
                          @"<a href=\"%@\"><img src=\"%@\" alt=\"%@\" class=\"alignnone size-full\" /></a>",
                          self.remoteURL, self.remoteURL, self.title];
            }
        }
    } else if (self.mediaType == MediaTypeVideo) {
        NSString *embedWidth = [NSString stringWithFormat:@"%@", self.width];
        NSString *embedHeight= [NSString stringWithFormat:@"%@", self.height];

        // Check for landscape resize
        if (([self.width intValue] > [self.height intValue]) && ([self.width intValue] > 640)) {
            embedWidth = @"640";
            embedHeight = @"360";
        } else if (([self.height intValue] > [self.width intValue]) && ([self.height intValue] > 640)) {
            embedHeight = @"640";
            embedWidth = @"360";
        }

        if (self.shortcode != nil) {
            result = self.shortcode;
        } else if (self.videopressGUID.length > 0) {
            result = [NSString stringWithFormat:
                      @"[wpvideo %@]",
                      self.videopressGUID];
        } else if (self.remoteURL != nil) {
            // Use HTML 5 <video> tag
            result = [NSString stringWithFormat:
                      @"<video src=\"%@\" controls=\"controls\" width=\"%@\" height=\"%@\">"
                      "Your browser does not support the video tag"
                      "</video>",
                      self.remoteURL,
                      embedWidth,
                      embedHeight];

            DDLogVerbose(@"media.html: %@", result);
        }
    }
    return result;
}

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

- (NSString *)posterImageURL
{
    if (!self.videopressGUID) {
        return self.remoteThumbnailURL;
    }

    NSString *posterURL = [self absoluteThumbnailLocalURL];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:posterURL isDirectory:nil]) {
        return posterURL;
    }
    posterURL = self.remoteThumbnailURL;
    return posterURL;
}

@end
