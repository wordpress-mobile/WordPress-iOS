#import "Media.h"
#import "WordPressData-Swift.h"

@implementation Media

@dynamic alt;
@dynamic mediaID;
@dynamic remoteURL;
@dynamic remoteLargeURL;
@dynamic remoteMediumURL;
@dynamic localURL;
@dynamic shortcode;
@dynamic width;
@dynamic length;
@dynamic title;
@dynamic height;
@dynamic filename;
@dynamic filesize;
@dynamic formattedSize;
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

- (BOOL)hasRemote {
    return self.mediaID.intValue != 0;
}

- (void)setError:(NSError *)error
{
    if (error != nil) {
        // Cherry pick keys that support secure coding. NSErrors thrown from the OS can
        // contain types that don't adopt NSSecureCoding, leading to a Core Data exception and crash.
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: error.localizedDescription};
        error = [NSError errorWithDomain:error.domain code:error.code userInfo:userInfo];
    }

    [self willChangeValueForKey:@"error"];
    [self setPrimitiveValue:error forKey:@"error"];
    [self didChangeValueForKey:@"error"];
}

@end
