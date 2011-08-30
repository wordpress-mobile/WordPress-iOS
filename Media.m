// 
//  Media.m
//  WordPress
//
//  Created by Chris Boyd on 6/23/10.
//  
//

#import "Media.h"
#import "UIImage+Resize.h"
#import "WPDataController.h"

@implementation Media 

@dynamic mediaType;
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
@synthesize uploader;

+ (Media *)newMediaForPost:(AbstractPost *)post {
    Media *media = [[Media alloc] initWithEntity:[NSEntityDescription entityForName:@"Media"
                                                          inManagedObjectContext:[post managedObjectContext]]
               insertIntoManagedObjectContext:[post managedObjectContext]];
    
    media.blog = post.blog;
    media.posts = [NSMutableSet setWithObject:post];
    
    return media;
}

- (void)awakeFromFetch {
    if (self.remoteStatus == MediaRemoteStatusPushing && self.uploader == nil) {
        self.remoteStatus = MediaRemoteStatusFailed;
    }
}

- (float)progress {
    [self willAccessValueForKey:@"progress"];
    NSNumber *result = [self primitiveValueForKey:@"progress"];
    [self didAccessValueForKey:@"progress"];
    return [result floatValue];
}

- (void)setProgress:(float)progress {
    [self willChangeValueForKey:@"progress"];
    [self setPrimitiveValue:[NSNumber numberWithFloat:progress] forKey:@"progress"];
    [self didChangeValueForKey:@"progress"];
}

- (MediaRemoteStatus)remoteStatus {
    return (MediaRemoteStatus)[[self remoteStatusNumber] intValue];
}

- (void)setRemoteStatus:(MediaRemoteStatus)aStatus {
    [self setRemoteStatusNumber:[NSNumber numberWithInt:aStatus]];
}

+ (NSString *)titleForRemoteStatus:(NSNumber *)remoteStatus {
    switch ([remoteStatus intValue]) {
        case MediaRemoteStatusPushing:
            return NSLocalizedString(@"Uploading", @"");
            break;
        case MediaRemoteStatusFailed:
            return NSLocalizedString(@"Failed", @"");
            break;
        case MediaRemoteStatusSync:
            return NSLocalizedString(@"Uploaded", @"");
            break;
        default:
            return NSLocalizedString(@"Pending", @"");
            break;
    }
}

- (NSString *)remoteStatusText {
    return [Media titleForRemoteStatus:self.remoteStatusNumber];
}

- (void)remove {
    if (self.uploader) {
        [self.uploader stop];
    }
    [[self managedObjectContext] deleteObject:self];
}

- (void)save {
    NSError *error;
    if (![[self managedObjectContext] save:&error]) {
        WPFLog(@"Unresolved Core Data Save error %@, %@", error, [error userInfo]);
        exit(-1);
    }
}

- (void)uploadInBackground {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    
    self.uploader = [[[WPMediaUploader alloc] initWithMedia:self] autorelease];
    [self.uploader start];
    [pool release];
}

- (void)didUploadInBackground {
    self.remoteStatus = MediaRemoteStatusSync;
    [self save];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MediaUploaded" object:self];
}

- (void)failedUploadInBackground {
    self.remoteStatus = MediaRemoteStatusFailed;
    self.uploader = nil;
    [self save];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MediaUploadFailed" object:self];
}

- (void)cancelUpload {
    [self.uploader stop];
    [self failedUploadInBackground];
}

- (void)upload {    
    self.remoteStatus = MediaRemoteStatusPushing;
    [self save];

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self performSelectorInBackground:@selector(uploadInBackground) withObject:nil];    
}

- (NSString *)html {
	NSString *result = @"";
	
	if(self.mediaType != nil) {
		if([self.mediaType isEqualToString:@"image"]) {
			if(self.shortcode != nil)
				result = self.shortcode;
			else if(self.remoteURL != nil)
				result = [NSString stringWithFormat:
						  @"<a href=\"%@\"><img src=\"%@\" alt=\"%@\" class=\"alignnone size-full\" /></a>",
						  self.remoteURL, self.remoteURL, self.filename, self.width, self.height];
		}
		else if([self.mediaType isEqualToString:@"video"]) {
			NSString *embedWidth = [NSString stringWithFormat:@"%@", self.width];
			NSString *embedHeight= [NSString stringWithFormat:@"%@", self.height];
			
			// Check for landscape resize
			if(([self.width intValue] > [self.height intValue]) && ([self.width intValue] > 640)) {
				embedWidth = @"640";
				embedHeight = @"360";
			}
			else if(([self.height intValue] > [self.width intValue]) && ([self.height intValue] > 640)) {
				embedHeight = @"640";
				embedWidth = @"360";
			}
			
			if(self.shortcode != nil)
				result = self.shortcode;
			else if(self.remoteURL != nil) {
				self.remoteURL = [self.remoteURL stringByReplacingOccurrencesOfString:@"\"" withString:@""];
				NSNumber *htmlPreference = [NSNumber numberWithInt:
											[[[NSUserDefaults standardUserDefaults] 
											  objectForKey:@"video_html_preference"] intValue]];
				
				if([htmlPreference intValue] == 0) {
					// Use HTML 5 <video> tag
					result = [NSString stringWithFormat:
							  @"<video src=\"%@\" controls=\"controls\" width=\"%@\" height=\"%@\">"
							  "Your browser does not support the video tag"
							  "</video>",
							  self.remoteURL, 
							  embedWidth, 
							  embedHeight];
				}
				else {
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
				
				NSLog(@"media.html: %@", result);
			}
		}
	}
	
	return result;
}

- (NSString *)mediaTypeName {
    if ([self.mediaType isEqualToString:@"image"]) {
        return NSLocalizedString(@"Image", @"");
    } else if ([self.mediaType isEqualToString:@"video"]) {
        return NSLocalizedString(@"Video", @"");
    } else {
        return self.mediaType;
    }
}

- (void)setImage:(UIImage *)image withSize:(MediaResize)size {
    CGSize newSize;
    switch (size) {
        case kResizeSmall:
			newSize = CGSizeMake(150, 150);
            break;
        case kResizeMedium:
            newSize = CGSizeMake(300, 300);
            break;
        case kResizeLarge:
            newSize = CGSizeMake(1024, 1024);
            break;
            
        default:
            newSize = image.size;
            break;
    }
    switch (image.imageOrientation) { 
        case UIImageOrientationUp: 
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDown: 
        case UIImageOrientationDownMirrored:
            self.orientation = @"landscape";
            break;
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            self.orientation = @"portrait";
            break;
        default:
            self.orientation = @"portrait";
    }

    //The dimensions of the image, taking orientation into account.
    CGSize originalSize = CGSizeMake(image.size.width, image.size.height);

    UIImage *resizedImage = image;
    if(image.size.width > newSize.width  && image.size.height > newSize.height)
        resizedImage = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFit
                                                   bounds:newSize
                                     interpolationQuality:kCGInterpolationHigh];
    else  
        resizedImage = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFit
                                                   bounds:originalSize
                                     interpolationQuality:kCGInterpolationHigh];

    NSData *imageData = UIImageJPEGRepresentation(resizedImage, 0.90);
	UIImage *imageThumbnail = [resizedImage thumbnailImage:75 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationHigh];
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyyMMdd-HHmmss"];
    
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *filename = [NSString stringWithFormat:@"%@.jpg", [formatter stringFromDate:[NSDate date]]];
    [formatter release]; formatter = nil;
	NSString *filepath = [documentsDirectory stringByAppendingPathComponent:filename];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager createFileAtPath:filepath contents:imageData attributes:nil];
    

	self.creationDate = [NSDate date];
	self.filename = filename;
	self.localURL = filepath;
	self.filesize = [NSNumber numberWithInt:(imageData.length/1024)];
	self.mediaType = @"image";
	self.thumbnail = UIImageJPEGRepresentation(imageThumbnail, 0.90);
	self.width = [NSNumber numberWithInt:resizedImage.size.width];
	self.height = [NSNumber numberWithInt:resizedImage.size.height];
}

@end
