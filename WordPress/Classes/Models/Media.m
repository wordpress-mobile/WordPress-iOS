#import "Media.h"
#import "UIImage+Resize.h"
#import "NSString+Helpers.h"
#import "NSString+Util.h"
#import "AFHTTPRequestOperation.h"
#import "ContextManager.h"
#import <ImageIO/ImageIO.h>

@interface Media (PrivateMethods)

- (void)xmlrpcUploadWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)xmlrpcDeleteWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)xmlrpcUpdateWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;

@end

@implementation Media {
    AFHTTPRequestOperation *_uploadOperation;
}

@dynamic mediaID;
@dynamic remoteURL;
@dynamic localURL;
@dynamic shortcode;
@dynamic width;
@dynamic length;
@dynamic title;
@dynamic thumbnail;
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

@synthesize unattached;

NSUInteger const MediaDefaultThumbnailSize = 75;
CGFloat const MediaDefaultJPEGCompressionQuality = 0.9;

+ (Media *)newMediaForPost:(AbstractPost *)post
{
    Media *media = [NSEntityDescription insertNewObjectForEntityForName:@"Media" inManagedObjectContext:post.managedObjectContext];
    media.blog = post.blog;
    media.posts = [NSMutableSet setWithObject:post];
    media.mediaID = @0;
    return media;
}

+ (Media *)newMediaForBlog:(Blog *)blog
{
    Media *media = [NSEntityDescription insertNewObjectForEntityForName:@"Media" inManagedObjectContext:blog.managedObjectContext];
    media.blog = blog;
    media.mediaID = @0;
    return media;
}

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
        return MediaTypeFeatured;
    }
    return MediaTypeDocument;
}

- (void)setMediaType:(MediaType)mediaType
{
    switch (mediaType) {
        case MediaTypeImage:
            self.mediaTypeString = @"image";
            break;
        case MediaTypeFeatured:
            self.mediaTypeString = @"featured";
            break;
        case MediaTypeVideo:
            self.mediaTypeString = @"video";
            break;
        case MediaTypePowerpoint:
            self.mediaTypeString = @"powerpoint";
            break;
        case MediaTypeDocument:
            self.mediaTypeString = @"document";
            break;
    }
}

- (NSString *)mediaTypeName
{
    if (self.mediaType == MediaTypeImage) {
        return NSLocalizedString(@"Image", @"");
    } else if (self.mediaType == MediaTypeVideo) {
        return NSLocalizedString(@"Video", @"");
    }

    return self.mediaTypeString;
}

- (BOOL)featured
{
    return self.mediaType == MediaTypeFeatured;
}

- (void)setFeatured:(BOOL)featured
{
    self.mediaType = featured ? MediaTypeFeatured : MediaTypeImage;
}

+ (NSString *)mediaTypeForFeaturedImage
{
    return @"image";
}

+ (void)bulkDeleteMedia:(NSArray *)media withSuccess:(void(^)())success failure:(void (^)(NSError *error, NSArray *failures))failure
{
    __block NSMutableArray *failedDeletes = [NSMutableArray array];
    for (NSUInteger i = 0; i < media.count; i++) {
        Media *m = media[i];
        // Delete locally if it was never uploaded
        if (!m.remoteURL) {
            [m.managedObjectContext deleteObject:m];
            if (i == media.count-1) {
                if (success) {
                    success();
                }
                return;
            }
            continue;
        }

        [m xmlrpcDeleteWithSuccess:^{
            if (i == media.count-1) {
                if (success) {
                    success();
                }
            }
        } failure:^(NSError *error) {
            [failedDeletes addObject:m];
            if (i == media.count-1) {
                if (failure) {
                    failure(error, failedDeletes);
                }
            }
        }];
    }
}

#pragma mark -

- (CGFloat)progress
{
    [self willAccessValueForKey:@"progress"];
    NSNumber *result = [self primitiveValueForKey:@"progress"];
    [self didAccessValueForKey:@"progress"];
    return [result floatValue];
}

- (void)setProgress:(CGFloat)progress
{
    [self willChangeValueForKey:@"progress"];
    [self setPrimitiveValue:[NSNumber numberWithFloat:progress] forKey:@"progress"];
    [self didChangeValueForKey:@"progress"];
}

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

- (void)remove
{
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:self.localURL error:&error];

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
        } else if (self.remoteURL != nil) {
            self.remoteURL = [self.remoteURL stringByReplacingOccurrencesOfString:@"\"" withString:@""];
            NSNumber *htmlPreference = [NSNumber numberWithInt:
                                        [[[NSUserDefaults standardUserDefaults]
                                          objectForKey:@"video_html_preference"] intValue]];

            if ([htmlPreference intValue] == 0) {
                // Use HTML 5 <video> tag
                result = [NSString stringWithFormat:
                          @"<video src=\"%@\" controls=\"controls\" width=\"%@\" height=\"%@\">"
                          "Your browser does not support the video tag"
                          "</video>",
                          self.remoteURL,
                          embedWidth,
                          embedHeight];
            } else {
                // Use HTML 4 <object><embed> tags
                embedHeight = [NSString stringWithFormat:@"%d", ([embedHeight intValue] + 16)];
                result = [NSString stringWithFormat:
                          @"<object classid=\"clsid:02BF25D5-8C17-4B23-BC80-D3488ABDDC6B\""
                          "codebase=\"http://www.apple.com/qtactivex/qtplugin.cab\""
                          "width=\"%@\" height=\"%@\">"
                          "<param name=\"src\" value=\"%@\">"
                          "<param name=\"autoplay\" value=\"false\">"
                          "<embed src=\"%@\" autoplay=\"false\" "
                          "width=\"%@\" height=\"%@\" type=\"video/quicktime\" "
                          "pluginspage=\"http://www.apple.com/quicktime/download/\" "
                          "/></object>",
                          embedWidth, embedHeight, self.remoteURL, self.remoteURL, embedWidth, embedHeight];
            }

            DDLogVerbose(@"media.html: %@", result);
        }
    }
    return result;
}

- (NSString *)thumbnailLocalURL;
{
    if ( self.localURL ) {
        return [NSString stringWithFormat:@"%@-thumbnail",self.localURL];
    } else {
        return nil;
    }
}
@end
