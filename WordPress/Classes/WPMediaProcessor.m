#import "WPMediaProcessor.h"
#import "Media.h"
#import "UIImage+Resize.h"
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>

// Notifications
extern NSString *const MediaFeaturedImageSelectedNotification;
extern NSString *const MediaShouldInsertBelowNotification;

@implementation WPMediaProcessor

- (id)init {
    if (self = [super init]) {
        
    }
    
    return self;
}

- (void)processImage:(UIImage *)theImage media:(Media *)imageMedia metadata:(NSDictionary *)metadata {
	NSData *imageData = UIImageJPEGRepresentation(theImage, 0.90);
	UIImage *imageThumbnail = [self generateThumbnailFromImage:theImage andSize:CGSizeMake(75, 75)];
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
        //this will be the data CGImageDestinationRef will write into
        NSMutableData *dest_data = [NSMutableData data];
        
		source = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
        if (source) {
            CFStringRef UTI = CGImageSourceGetType(source); //this is the type of image (e.g., public.jpeg)
            destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)dest_data,UTI,1,NULL);
            
            if(destination) {
                //add the image contained in the image source to the destination, copying the old metadata
                CGImageDestinationAddImageFromSource(destination,source,0, (__bridge CFDictionaryRef) metadata);
                
                //tell the destination to write the image data and metadata into our data object.
                //It will return false if something goes wrong
                success = CGImageDestinationFinalize(destination);
            } else {
                DDLogWarn(@"***Could not create image destination ***");
            }
        } else {
            DDLogWarn(@"***Could not create image source ***");
        }
		
		if(!success) {
            DDLogWarn(@"***Could not create data from image destination ***");
			//write the data without EXIF to disk
			NSFileManager *fileManager = [NSFileManager defaultManager];
			[fileManager createFileAtPath:filepath contents:imageData attributes:nil];
		} else {
			//write it to disk
			[dest_data writeToFile:filepath atomically:YES];
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
//    if (_selectingFeaturedImage) {
//        imageMedia.featured = YES;
//    } else {
        imageMedia.mediaType = MediaTypeImage;
//    }
	imageMedia.thumbnail = UIImageJPEGRepresentation(imageThumbnail, 0.90);
	imageMedia.width = [NSNumber numberWithInt:theImage.size.width];
	imageMedia.height = [NSNumber numberWithInt:theImage.size.height];
    
    [imageMedia uploadWithSuccess:^{
        if ([imageMedia isDeleted]) {
            NSLog(@"Media deleted while uploading (%@)", imageMedia);
            return;
        }
//        if (_selectingFeaturedImage) {
//            [self.post setFeaturedImage:imageMedia];
//            [[NSNotificationCenter defaultCenter] postNotificationName:MediaFeaturedImageSelectedNotification object:imageMedia];
//        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:MediaShouldInsertBelowNotification object:imageMedia];
//        }
        [imageMedia save];
    } failure:^(NSError *error) {
        if (error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled) {
            return;
        }
        
        [WPError showAlertWithTitle:NSLocalizedString(@"Upload failed", nil) message:error.localizedDescription];
    }];
}

- (UIImage *)generateThumbnailFromImage:(UIImage *)theImage andSize:(CGSize)targetSize {
    return [theImage thumbnailImage:75 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationHigh];
}


@end
