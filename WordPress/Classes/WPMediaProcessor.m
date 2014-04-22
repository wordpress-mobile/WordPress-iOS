#import "WPMediaProcessor.h"
#import "Media.h"
#import "UIImage+Resize.h"
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>

NSUInteger const WPMediaThumbnailSize = 75;
CGFloat const WPMediaJPEGCompressionQuality = 0.9;

// Notifications
extern NSString *const MediaFeaturedImageSelectedNotification;
extern NSString *const MediaShouldInsertBelowNotification;

@implementation WPMediaProcessor

- (void)processImage:(UIImage *)theImage media:(Media *)imageMedia metadata:(NSDictionary *)metadata
{
	NSData *imageData = UIImageJPEGRepresentation(theImage, WPMediaJPEGCompressionQuality);
	UIImage *imageThumbnail = [self generateThumbnailFromImage:theImage andSize:CGSizeMake(WPMediaThumbnailSize, WPMediaThumbnailSize)];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [NSLocale currentLocale];
	[dateFormatter setDateFormat:@"yyyyMMdd-HHmmss"];
    
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *filename = [NSString stringWithFormat:@"%@.jpg", [dateFormatter stringFromDate:[NSDate date]]];
	NSString *filepath = [documentsDirectory stringByAppendingPathComponent:filename];
    
	if (metadata != nil) {
		// Write the EXIF data with the image data to disk
		CGImageSourceRef  source = NULL;
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
            } else {
                DDLogWarn(@"Media processor could not create image destination");
            }
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
	imageMedia.thumbnail = UIImageJPEGRepresentation(imageThumbnail, WPMediaJPEGCompressionQuality);
	imageMedia.width = @(theImage.size.width);
	imageMedia.height = @(theImage.size.height);
    
    [imageMedia uploadWithSuccess:^{
        if ([imageMedia isDeleted]) {
            DDLogWarn(@"Media processor found deleted media while uploading (%@)", imageMedia);
            return;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:MediaShouldInsertBelowNotification object:imageMedia];
        [imageMedia save];
    } failure:^(NSError *error) {
        if (error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled) {
            DDLogWarn(@"Media processor failed with cancelled upload: %@", error.localizedDescription);
            return;
        }
        
        [WPError showAlertWithTitle:NSLocalizedString(@"Upload failed", nil) message:error.localizedDescription];
    }];
}

- (CGSize)sizeForImage:(UIImage *)image
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

- (UIImage *)resizeImage:(UIImage *)original toSize:(CGSize)newSize
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

- (MediaResize)mediaResizePreference
{
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    NSNumber *resizePreferenceNumber = @(0);
    NSString *resizePreferenceString = [[NSUserDefaults standardUserDefaults] objectForKey:@"media_resize_preference"];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"media_resize_preference"] != nil)
        resizePreferenceNumber = [numberFormatter numberFromString:resizePreferenceString];
    
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

- (UIImage *)generateThumbnailFromImage:(UIImage *)theImage andSize:(CGSize)targetSize
{
    return [theImage thumbnailImage:WPMediaThumbnailSize transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationHigh];
}

- (NSDictionary *)metadataForAsset:(ALAsset *)asset enableGeolocation:(BOOL)enableGeolocation
{
    ALAssetRepresentation *rep = [asset defaultRepresentation];

    Byte *buf = malloc([rep size]);  // will be freed automatically when associated NSData is deallocated
    NSError *err = nil;
    NSUInteger bytes = [rep getBytes:buf fromOffset:0LL length:[rep size] error:&err];
    if (err || bytes == 0) {
        // Are err and bytes == 0 redundant? Doc says 0 return means
        // error occurred which presumably means NSError is returned.
        free(buf); // Free up memory so we don't leak.
        DDLogError(@"error from getBytes: %@", err);
       
        return nil;
    }
    NSData *imageJPEG = [NSData dataWithBytesNoCopy:buf
                                             length:[rep size]
                                       freeWhenDone:YES];  // YES means free malloc'ed buf that backs this when deallocated
   
    CGImageSourceRef  source ;
    source = CGImageSourceCreateWithData((__bridge CFDataRef)imageJPEG, NULL);
   
    NSDictionary *metadata = (NSDictionary *) CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source,0,NULL));
    CFRelease(source);

    // Make the metadata dictionary mutable so we can remove properties from it
    NSMutableDictionary *metadataAsMutable = [metadata mutableCopy];
   
    if (!enableGeolocation) {
       // We should remove the GPS info if the blog has the geolocation set to off
       [metadataAsMutable removeObjectForKey:@"{GPS}"];
    }
    [metadataAsMutable removeObjectForKey:@"Orientation"];
    [metadataAsMutable removeObjectForKey:@"{TIFF}"];
   
    return [NSDictionary dictionaryWithDictionary:metadataAsMutable];
}

@end
