#import "DisplayableImageHelper.h"

static const NSInteger FeaturedImageMinimumWidth = 150;

static NSString * const AttachmentsDictionaryKeyWidth = @"width";
static NSString * const AttachmentsDictionaryKeyURL = @"URL";
static NSString * const AttachmentsDictionaryKeyMimeType = @"mime_type";

@implementation DisplayableImageHelper

+ (NSString *)searchPostAttachmentsForImageToDisplay:(NSDictionary *)attachmentsDict existingInContent:(NSString *)content
{
    NSArray *attachments = [attachmentsDict allValues];
    if ([attachments count] == 0) {
        return nil;
    }

    NSString *imageToDisplay;

    attachments = [self filteredAttachmentsArray:attachments];

    for (NSDictionary *attachment in attachments) {
        NSInteger width = [[attachment numberForKey:AttachmentsDictionaryKeyWidth] integerValue];
        if (width < FeaturedImageMinimumWidth) {
            // The remaining images are too small so just stop now.
            break;
        }
        NSString *maybeImage = [attachment stringForKey:AttachmentsDictionaryKeyURL];
        if ([content containsString:maybeImage]) {
            imageToDisplay = maybeImage;
            break;
        }
    }

    return imageToDisplay;
}

+ (NSArray *)filteredAttachmentsArray:(NSArray *)attachments
{
    NSString *key = AttachmentsDictionaryKeyMimeType;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K BEGINSWITH %@", key, @"image"];
    attachments = [attachments filteredArrayUsingPredicate:predicate];
    attachments = [self sortAttachmentsArray:attachments];
    return attachments;
}

+ (NSArray *)sortAttachmentsArray:(NSArray *)attachments
{
    return [attachments sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *attachmentA, NSDictionary *attachmentB) {
        NSString *key = AttachmentsDictionaryKeyWidth;
        NSNumber *widthA = [attachmentA numberForKey:key] ?: @(0);
        NSNumber *widthB = [attachmentB numberForKey:key] ?: @(0);

        if ([widthA integerValue] < [widthB integerValue]) {
            return NSOrderedDescending;
        } else if ([widthA integerValue] > [widthB integerValue]) {
            return NSOrderedAscending;
        } else {
            return NSOrderedSame;
        }
    }];
}

+ (NSString *)searchPostContentForImageToDisplay:(NSString *)content
{
    NSString *imageSrc = @"";
    // If there is no image tag in the content, just bail.
    if (!content || [content rangeOfString:@"<img"].location == NSNotFound) {
        return imageSrc;
    }

    // Get all the things
    static NSRegularExpression *regex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error;
        NSString *imgPattern = @"<img(\\s+.*?)(?:src\\s*=\\s*(?:'|\")(.*?)(?:'|\"))(.*?)>";
        regex = [NSRegularExpression regularExpressionWithPattern:imgPattern options:NSRegularExpressionCaseInsensitive error:&error];
    });

    // Find all the image tags in the content passed.
    NSArray *matches = [regex matchesInString:content options:0 range:NSMakeRange(0, [content length])];

    for (NSTextCheckingResult *match in matches) {
        NSString *tag = [content substringWithRange:match.range];
        NSString *src = [self extractSrcFromImgTag:tag];

        // Ignore WordPress emoji images
        if ([src rangeOfString:@"/images/core/emoji/"].location != NSNotFound ||
            [src rangeOfString:@"/wp-includes/images/smilies/"].location != NSNotFound ||
            [src rangeOfString:@"/wp-content/mu-plugins/wpcom-smileys/"].location != NSNotFound) {
            continue;
        }

        // Ignore .svg images since we can't display them in a UIImageView
        if ([src rangeOfString:@".svg"].location != NSNotFound) {
            continue;
        }

        // Check the tag for a good width
        NSInteger width = MAX([self widthFromElementAttribute:tag], [self widthFromQueryString:src]);
        if (width > FeaturedImageMinimumWidth) {
            imageSrc = src;
            break;
        }
    }
    if (imageSrc.length == 0) {
        imageSrc = [self searchContentBySizeClassForImageToFeature:content];
    }

    return imageSrc;
}

+ (NSSet *)searchPostContentForAttachmentIdsInGalleries:(NSString *)content
{
    NSMutableSet *resultSet = [NSMutableSet set];
    // If there is no gallery shortcode in the content, just bail.
    if (!content || [content rangeOfString:@"[gallery "].location == NSNotFound) {
        return resultSet;
    }

    // Get all the things
    static NSRegularExpression *regexGallery;
    static dispatch_once_t onceTokenRegexGallery;
    dispatch_once(&onceTokenRegexGallery, ^{
        NSError *error;
        NSString *galleryPattern = @"\\[gallery[^]]+ids=\"([0-9,]*)\"[^]]*\\]";
        regexGallery = [NSRegularExpression regularExpressionWithPattern:galleryPattern options:NSRegularExpressionCaseInsensitive error:&error];
    });

    // Find all the gallery shortcodes in the content passed.
    NSArray *matches = [regexGallery matchesInString:content options:0 range:NSMakeRange(0, [content length])];

    for (NSTextCheckingResult *match in matches) {
        if (match.numberOfRanges < 2) {
            continue;
        }
        NSString *tag = [content substringWithRange:[match rangeAtIndex:1]];
        NSSet *tagIds = [self idsFromGallery:tag];
        [resultSet unionSet:tagIds];
    }
    return resultSet;
}

/**
 Extract the path to an image from an image tag.
 
 @param tag An image tag.
 @return The value of the src param.
 */
+ (NSString *)extractSrcFromImgTag:(NSString *)tag
{
    static NSRegularExpression *regex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error;
        NSString *srcPattern = @"src\\s*=\\s*(?:'|\")(.*?)(?:'|\")";
        regex = [NSRegularExpression regularExpressionWithPattern:srcPattern options:NSRegularExpressionCaseInsensitive error:&error];
    });

    NSRange srcRng = [regex rangeOfFirstMatchInString:tag options:0 range:NSMakeRange(0, [tag length])];
    NSString *src = [tag substringWithRange:srcRng];
    NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"\"'="];
    NSRange quoteRng = [src rangeOfCharacterFromSet:charSet];
    src = [src substringFromIndex:quoteRng.location];
    src = [src stringByTrimmingCharactersInSet:charSet];
    return src;
}

/**
 Search the passed string for an image that is a good candidate to feature.
 @param content The content string to search.
 @return The url path for the image or an empty string.
 */
+ (NSString *)searchContentBySizeClassForImageToFeature:(NSString *)content
{
    NSString *str = @"";
    // If there is no image tag in the content, just bail.
    if (!content || [content rangeOfString:@"<img"].location == NSNotFound) {
        return str;
    }
    // If there is not a large or full sized image, just bail.
    NSString *className = @"size-full";
    NSRange range = [content rangeOfString:className];
    if (range.location == NSNotFound) {
        className = @"size-large";
        range = [content rangeOfString:className];
        if (range.location == NSNotFound) {
            className = @"size-medium";
            range = [content rangeOfString:className];
            if (range.location == NSNotFound) {
                return str;
            }
        }
    }
    // find the start of the image
    range = [content rangeOfString:@"<img" options:NSBackwardsSearch | NSCaseInsensitiveSearch range:NSMakeRange(0, range.location)];
    if (range.location == NSNotFound) {
        return str;
    }
    // Build the regex once and keep it around for subsequent calls.
    static NSRegularExpression *regex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error;
        NSString *pattern = @"src=\"\\S+\"";
        regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    });
    NSInteger length = [content length] - range.location;
    range = [regex rangeOfFirstMatchInString:content options:0 range:NSMakeRange(range.location, length)];
    if (range.location == NSNotFound) {
        return str;
    }
    range = NSMakeRange(range.location+5, range.length-6);
    str = [content substringWithRange:range];
    str = [[str componentsSeparatedByString:@"?"] objectAtIndex:0];
    return str;
}

+ (NSInteger)widthFromElementAttribute:(NSString *)tag
{
    NSRange rng = [tag rangeOfString:@"width=\""];
    if (rng.location == NSNotFound) {
        return 0;
    }
    NSInteger startingIdx = rng.location + rng.length;
    rng = [tag rangeOfString:@"\"" options:NSCaseInsensitiveSearch range:NSMakeRange(startingIdx, [tag length] - startingIdx)];
    if (rng.location == NSNotFound) {
        return 0;
    }

    NSString *widthStr = [tag substringWithRange:NSMakeRange(startingIdx, rng.location - startingIdx)];
    return [widthStr integerValue];
}

+ (NSInteger)widthFromQueryString:(NSString *)src
{
    NSURL *url = [NSURL URLWithString:src];
    NSString *query = [url query];
    NSRange rng = [query rangeOfString:@"w="];
    if (rng.location == NSNotFound) {
        return 0;
    }

    NSString *str = [query substringFromIndex:rng.location + rng.length];
    NSString *widthStr = [[str componentsSeparatedByString:@"&"] firstObject];

    return [widthStr integerValue];
}

+ (NSSet *)idsFromGallery:(NSString *)idsStr
{
    NSArray * imageIds = [idsStr componentsSeparatedByString:@","];
    NSMutableSet *result = [NSMutableSet set];
    for (NSString *imageIdStr in imageIds) {
        NSNumber *numberId = [imageIdStr numericValue];
        if (numberId) {
            [result addObject:numberId];
        }
    }
    return result;
}
@end
