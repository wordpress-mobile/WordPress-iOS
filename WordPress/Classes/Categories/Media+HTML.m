#import "Media+HTML.h"

@implementation Media (HTML)

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

- (NSString *)posterAttributeImageURL
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
