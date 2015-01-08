#import "WPMediaSizing.h"
#import "UIImage+Resize.h"

@implementation WPMediaSizing

+ (MediaResize)mediaResizePreference
{
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    NSNumber *resizePreferenceNumber = @(0);
    NSString *resizePreferenceString = [[NSUserDefaults standardUserDefaults] objectForKey:@"media_resize_preference"];

    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"media_resize_preference"] != nil) {
        resizePreferenceNumber = [numberFormatter numberFromString:resizePreferenceString];
    }

    NSInteger resizePreferenceIndex = [resizePreferenceNumber integerValue];

    // Need to deal with preference index awkwardly due to the way we're storing preferences
    if (resizePreferenceIndex == 0) {
        // We used to support per-image resizing; replace that with large by default
        return MediaResizeLarge;
    } else if (resizePreferenceIndex == 1) {
        return MediaResizeSmall;
    } else if (resizePreferenceIndex == 2) {
        return MediaResizeMedium;
    } else if (resizePreferenceIndex == 3) {
        return MediaResizeLarge;
    }

    return MediaResizeOriginal;
}

+ (CGSize)sizeForImage:(UIImage *)image
           mediaResize:(MediaResize)resize
  blogResizeDimensions:(NSDictionary *)dimensions
{
    CGSize smallSize =  [dimensions[@"smallSize"] CGSizeValue];
    CGSize mediumSize = [dimensions[@"mediumSize"] CGSizeValue];
    CGSize largeSize =  [dimensions[@"largeSize"] CGSizeValue];
    CGSize originalSize = CGSizeMake(image.size.width, image.size.height);

    // Resize the image using the selected dimensions
    CGSize newSize = originalSize;

    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            smallSize = CGSizeMake(smallSize.height, smallSize.width);
            mediumSize = CGSizeMake(mediumSize.height, mediumSize.width);
            largeSize = CGSizeMake(largeSize.height, largeSize.width);
            break;
        default:
            break;
    }

    if (resize == MediaResizeSmall &&
        (image.size.width > smallSize.width || image.size.height > smallSize.height)) {
        newSize = smallSize;
    } else if (resize == MediaResizeMedium &&
               (image.size.width > mediumSize.width || image.size.height > mediumSize.height)) {
        newSize = mediumSize;
    } else if (resize == MediaResizeLarge &&
               (image.size.width > largeSize.width || image.size.height > largeSize.height)) {
        newSize = largeSize;
    }

    return newSize;
}

+ (UIImage *)resizeImage:(UIImage *)original toSize:(CGSize)newSize
{
    CGSize originalSize = CGSizeMake(original.size.width, original.size.height);
    UIImage *resizedImage = original;

    // Perform resizing if necessary
    if (!CGSizeEqualToSize(originalSize, newSize)) {
        resizedImage = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFit
                                                      bounds:newSize
                                        interpolationQuality:kCGInterpolationHigh];
    }

    return resizedImage;
}

+ (UIImage *)correctlySizedImage:(UIImage *)fullResolutionImage forBlogDimensions:(NSDictionary *)dimensions
{
    MediaResize *resize = [self mediaResizePreference];
    CGSize newSize = [self sizeForImage:fullResolutionImage mediaResize:resize blogResizeDimensions:dimensions];
    return [self resizeImage:fullResolutionImage toSize:newSize];
}

@end
