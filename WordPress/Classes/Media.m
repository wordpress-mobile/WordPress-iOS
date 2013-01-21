// 
//  Media.m
//  WordPress
//
//  Created by Chris Boyd on 6/23/10.
//  
//

#import "Media.h"
#import "UIImage+Resize.h"
#import "NSString+Helpers.h"
#import "AFHTTPRequestOperation.h"

@interface Media (PrivateMethods)
- (void)xmlrpcUploadWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure ;
@end

@implementation Media {
    AFHTTPRequestOperation *_uploadOperation;
}

@dynamic mediaID;
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

+ (Media *)newMediaForPost:(AbstractPost *)post {
    Media *media = [[Media alloc] initWithEntity:[NSEntityDescription entityForName:@"Media"
                                                          inManagedObjectContext:[post managedObjectContext]]
               insertIntoManagedObjectContext:[post managedObjectContext]];
    
    media.blog = post.blog;
    media.posts = [NSMutableSet setWithObject:post];
    
    return media;
}

- (void)awakeFromFetch {
    if ((self.remoteStatus == MediaRemoteStatusPushing && _uploadOperation == nil) || (self.remoteStatus == MediaRemoteStatusProcessing)) {
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
    [self cancelUpload];
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:self.localURL error:&error];
    [[self managedObjectContext] deleteObject:self];
}

- (void)save {
    NSError *error;
    if (![[self managedObjectContext] save:&error]) {
        WPFLog(@"Unresolved Core Data Save error %@, %@", error, [error userInfo]);
        exit(-1);
    }
}

- (void)cancelUpload {
    if (self.remoteStatus == MediaRemoteStatusPushing || self.remoteStatus == MediaRemoteStatusProcessing) {
        [_uploadOperation cancel];
        _uploadOperation = nil;
        self.remoteStatus = MediaRemoteStatusFailed;
    }
}

- (void)uploadWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    [self save];
    self.progress = 0.0f;
    
    [self xmlrpcUploadWithSuccess:success failure:failure];
}

- (void)xmlrpcUploadWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    NSString *mimeType = ([self.mediaType isEqualToString:@"video"]) ? @"video/mp4" : @"image/jpeg";
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:
                            mimeType, @"type",
                            self.filename, @"name",
                            [NSInputStream inputStreamWithFileAtPath:self.localURL], @"bits",
                            nil];
    NSArray *parameters = [self.blog getXMLRPCArgsWithExtra:object];

    self.remoteStatus = MediaRemoteStatusProcessing;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^(void) {
        // Create the request asynchronously
        // TODO: use streaming to avoid processing on memory
        NSMutableURLRequest *request = [self.blog.api requestWithMethod:@"metaWeblog.newMediaObject" parameters:parameters];

        dispatch_async(dispatch_get_main_queue(), ^(void) {
            AFHTTPRequestOperation *operation = [self.blog.api HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
                if ([self isDeleted] || self.managedObjectContext == nil)
                    return;

                NSDictionary *response = (NSDictionary *)responseObject;
                if([response objectForKey:@"videopress_shortcode"] != nil)
                    self.shortcode = [response objectForKey:@"videopress_shortcode"];

                if([response objectForKey:@"url"] != nil)
                    self.remoteURL = [response objectForKey:@"url"];
                
                if ([response objectForKey:@"id"] != nil) {
                    self.mediaID = [[response objectForKey:@"id"] numericValue];
                }

                self.remoteStatus = MediaRemoteStatusSync;
                 _uploadOperation = nil;
                if (success) success();

                if([self.mediaType isEqualToString:@"video"]) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:VideoUploadSuccessful
                                                                        object:self
                                                                      userInfo:response];
                } else if ([self.mediaType isEqualToString:@"image"]){ 
                    [[NSNotificationCenter defaultCenter] postNotificationName:ImageUploadSuccessful
                                                                        object:self
                                                                      userInfo:response];
                } else if ([self.mediaType isEqualToString:@"featured"]){
                    [[NSNotificationCenter defaultCenter] postNotificationName:FeaturedImageUploadSuccessful
                                                                        object:self
                                                                      userInfo:response];
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                if ([self isDeleted] || self.managedObjectContext == nil)
                    return;
                
                if ([self.mediaType isEqualToString:@"featured"]) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:FeaturedImageUploadFailed
                                                                        object:self];
                }

                self.remoteStatus = MediaRemoteStatusFailed;
                 _uploadOperation = nil;
                if (failure) failure(error);
            }];
            [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    if ([self isDeleted] || self.managedObjectContext == nil)
                        return;
                    self.progress = (float)totalBytesWritten / (float)totalBytesExpectedToWrite;
                });
            }];
            _uploadOperation = operation;

            // Upload might have been canceled while processing
            if (self.remoteStatus == MediaRemoteStatusProcessing) {
                self.remoteStatus = MediaRemoteStatusPushing;
                [self.blog.api enqueueHTTPRequestOperation:operation];
            }
        });
    });
}

- (NSString *)html {
	NSString *result = @"";
	
	if(self.mediaType != nil) {
		if([self.mediaType isEqualToString:@"image"]) {
			if(self.shortcode != nil)
				result = self.shortcode;
			else if(self.remoteURL != nil) {
                NSString *linkType = nil;
                if( [[self.blog getOptionValue:@"image_default_link_type"] isKindOfClass:[NSString class]] )
                    linkType = (NSString *)[self.blog getOptionValue:@"image_default_link_type"];
                else
                    linkType = @"";
                
                if ([linkType isEqualToString:@"none"]) {
                    result = [NSString stringWithFormat:
                              @"<img src=\"%@\" alt=\"%@\" class=\"alignnone size-full\" />",
                              self.remoteURL, self.filename];
                } else {
                    result = [NSString stringWithFormat:
                              @"<a href=\"%@\"><img src=\"%@\" alt=\"%@\" class=\"alignnone size-full\" /></a>",
                              self.remoteURL, self.remoteURL, self.filename];
                }
            }
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
    //Read the predefined resizeDimensions and fix them by using the image orietation
    NSDictionary* predefDim = [self.blog getImageResizeDimensions];
    CGSize smallSize =  [[predefDim objectForKey: @"smallSize"] CGSizeValue];
    CGSize mediumSize = [[predefDim objectForKey: @"mediumSize"] CGSizeValue];
    CGSize largeSize =  [[predefDim objectForKey: @"largeSize"] CGSizeValue];
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
    
    CGSize newSize;
    switch (size) {
        case kResizeSmall:
			newSize = smallSize;
            break;
        case kResizeMedium:
            newSize = mediumSize;
            break;
        case kResizeLarge:
            newSize = largeSize;
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
    if(image.size.width > newSize.width || image.size.height > newSize.height)
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
