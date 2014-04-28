#import "WPMediaPersister.h"
#import <ImageIO/ImageIO.h>
#import "Media.h"
#import "UIImage+Resize.h"

@implementation WPMediaPersister

NSUInteger const WPMediaPersisterThumbnailSize = 75;
CGFloat const WPMediaPersisterJPEGCompressionQuality = 0.9;

+ (void)saveMedia:(Media *)imageMedia withImage:(UIImage *)image andMetadata:(NSDictionary *)metadata
{
    NSData *imageData = UIImageJPEGRepresentation(image, WPMediaPersisterJPEGCompressionQuality);
    UIImage *imageThumbnail = [self generateThumbnailFromImage:image andSize:CGSizeMake(WPMediaPersisterThumbnailSize, WPMediaPersisterThumbnailSize)];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [NSLocale currentLocale];
    [dateFormatter setDateFormat:@"yyyyMMdd-HHmmss"];

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filename = [NSString stringWithFormat:@"%@.jpg", [dateFormatter stringFromDate:[NSDate date]]];
    NSString *filepath = [documentsDirectory stringByAppendingPathComponent:filename];

    if (metadata != nil) {
        // Write the EXIF data with the image data to disk
        CGImageSourceRef source = NULL;
        CGImageDestinationRef destination = NULL;
        BOOL success = NO;
        // This will be the data CGImageDestinationRef will write into
        NSMutableData *destinationData = [NSMutableData data];

        source = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
        if (source) {
            CFStringRef UTI = CGImageSourceGetType(source); // this is the type of image (e.g., public.jpeg)
            destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)destinationData,UTI,1,NULL);

            if(destination) {
                // Add the image contained in the image source to the destination, copying the old metadata
                CGImageDestinationAddImageFromSource(destination, source,0, (__bridge CFDictionaryRef) metadata);

                // Tell the destination to write the image data and metadata into our data object
                // It will return false if something goes wrong
                success = CGImageDestinationFinalize(destination);
                CFRelease(destination);
            } else {
                DDLogWarn(@"Media processor could not create image destination");
            }

            CFRelease(source);
        } else {
            DDLogWarn(@"Media processor could not create image source");
        }

        if (!success) {
            DDLogWarn(@"Media processor could not create data from image destination");
            // Write the data without EXIF to disk
            NSFileManager *fileManager = [NSFileManager defaultManager];
            [fileManager createFileAtPath:filepath contents:imageData attributes:nil];
        } else {
            [destinationData writeToFile:filepath atomically:YES];
        }
    } else {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager createFileAtPath:filepath contents:imageData attributes:nil];
    }

    UIDeviceOrientation currentOrientation = [UIDevice currentDevice].orientation;
    imageMedia.orientation = UIDeviceOrientationIsLandscape(currentOrientation) ? @"landscape" : @"portrait";
    imageMedia.creationDate = [NSDate date];
    imageMedia.filename = filename;
    imageMedia.localURL = filepath;
    imageMedia.filesize = @(imageData.length/1024);
    imageMedia.mediaType = MediaTypeImage;
    imageMedia.thumbnail = UIImageJPEGRepresentation(imageThumbnail, WPMediaPersisterJPEGCompressionQuality);
    imageMedia.width = @(image.size.width);
    imageMedia.height = @(image.size.height);
    [imageMedia save];
}

+ (UIImage *)generateThumbnailFromImage:(UIImage *)theImage andSize:(CGSize)targetSize
{
    return [theImage thumbnailImage:WPMediaPersisterThumbnailSize transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationHigh];
}


@end
