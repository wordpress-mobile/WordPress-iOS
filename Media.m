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

@interface Media (PrivateMethods)
- (void)xmlrpcUploadWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure ;
- (void)atomPubUploadWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
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
@synthesize uploader;

- (void)dealloc {
    [_uploadOperation release]; _uploadOperation = nil;
    [super dealloc];
}

+ (Media *)newMediaForPost:(AbstractPost *)post {
    Media *media = [[Media alloc] initWithEntity:[NSEntityDescription entityForName:@"Media"
                                                          inManagedObjectContext:[post managedObjectContext]]
               insertIntoManagedObjectContext:[post managedObjectContext]];
    
    media.blog = post.blog;
    media.posts = [NSMutableSet setWithObject:post];
    
    return media;
}

- (void)awakeFromFetch {
    if ((self.remoteStatus == MediaRemoteStatusPushing && self.uploader == nil) || (self.remoteStatus == MediaRemoteStatusProcessing)) {
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

- (void)cancelUpload {
    [_uploadOperation cancel];
    [_uploadOperation release]; _uploadOperation = nil;
    self.remoteStatus = MediaRemoteStatusFailed;
}

- (void)uploadWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    [self save];
    self.progress = 0.0f;
    
    if (!self.blog.isWPcom && [self.mediaType isEqualToString:@"video"] && [[[NSUserDefaults standardUserDefaults] objectForKey:@"video_api_preference"] intValue] == 1) {
        [self atomPubUploadWithSuccess:success failure:failure];
    } else {
        [self xmlrpcUploadWithSuccess:success failure:failure];
    }
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

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        // Create the request asynchronously
        // TODO: use streaming to avoid processing on memory
        NSMutableURLRequest *request = [self.blog.api requestWithMethod:@"metaWeblog.newMediaObject" parameters:parameters];

        dispatch_async(dispatch_get_main_queue(), ^(void) {
            AFHTTPRequestOperation *operation = [self.blog.api HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSDictionary *response = (NSDictionary *)responseObject;
                if([response objectForKey:@"videopress_shortcode"] != nil)
                    self.shortcode = [response objectForKey:@"videopress_shortcode"];

                if([response objectForKey:@"url"] != nil)
                    self.remoteURL = [response objectForKey:@"url"];
                
                if ([response objectForKey:@"id"] != nil) {
                    self.mediaID = [[response objectForKey:@"id"] numericValue];
                }

                self.remoteStatus = MediaRemoteStatusSync;
                [_uploadOperation release]; _uploadOperation = nil;
                if (success) success();

                if([self.mediaType isEqualToString:@"video"]) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:VideoUploadSuccessful
                                                                        object:self
                                                                      userInfo:response];
                } else {
                    [[NSNotificationCenter defaultCenter] postNotificationName:ImageUploadSuccessful
                                                                        object:self
                                                                      userInfo:response];
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                self.remoteStatus = MediaRemoteStatusFailed;
                [_uploadOperation release]; _uploadOperation = nil;
                if (failure) failure(error);
            }];
            [operation setUploadProgressBlock:^(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite) {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    self.progress = (float)totalBytesWritten / (float)totalBytesExpectedToWrite;
                });
            }];
            _uploadOperation = [operation retain];
            self.remoteStatus = MediaRemoteStatusPushing;
            [self.blog.api enqueueHTTPRequestOperation:operation];
        });
    });
}

- (void)atomPubUploadWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
   	NSString *blogURL = [self.blog.xmlrpc stringByReplacingOccurrencesOfString:@"xmlrpc.php" withString:@"wp-app.php/attachments"];
	NSURL *atomURL = [NSURL URLWithString:blogURL];

	NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.localURL error:nil];
	NSString *contentType = @"image/jpeg";
	if([self.mediaType isEqualToString:@"video"])
		contentType = @"video/mp4";
	NSString *username = self.blog.username;
	NSString *password = [self.blog fetchPassword];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:atomURL];
    NSString *authentication = [NSString stringWithFormat:@"Basic %@", [[NSString stringWithFormat:@"%@:%@",username,password] base64Encoding]];
    [request setValue:authentication forHTTPHeaderField:@"Authorization"];
    [request setValue:[[NSUserDefaults standardUserDefaults] objectForKey:@"UserAgent"] forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
    [request setValue:[NSString stringWithFormat:@"%d", [[attributes objectForKey:NSFileSize] intValue]] forHTTPHeaderField:@"Content-Length"];
    [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBodyStream:[NSInputStream inputStreamWithFileAtPath:self.localURL]];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (operation.responseString != nil && ![operation.responseString isEmpty]) {
            if ([operation.responseString rangeOfString:@"AtomPub services are disabled"].location != NSNotFound) {
                if (failure) {
                    NSError *error = [NSError errorWithDomain:@"org.wordpress" code:0 userInfo:[NSDictionary dictionaryWithObject:operation.responseString forKey:NSLocalizedDescriptionKey]];
                    self.remoteStatus = MediaRemoteStatusFailed;
                    [_uploadOperation release]; _uploadOperation = nil;
                    failure(error);
                }
            } else {
                // TODO: we should use regxep to capture other type of errors!!
                // atom pub services could be enabled but errors can occur.
                NSMutableDictionary *videoMeta = [[NSMutableDictionary alloc] init];
                NSString *regEx = @"src=\"([^\"]*)\"";
                NSString *link = [operation.responseString stringByMatching:regEx capture:1];
                link = [link stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                [videoMeta setObject:link forKey:@"url"];
                self.remoteURL = link;
                self.remoteStatus = MediaRemoteStatusSync;
                [_uploadOperation release]; _uploadOperation = nil;
                if (success) success();
                [[NSNotificationCenter defaultCenter] postNotificationName:VideoUploadSuccessful
                                                                    object:self
                                                                  userInfo:videoMeta];
                [videoMeta release];
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        self.remoteStatus = MediaRemoteStatusFailed;
        [_uploadOperation release]; _uploadOperation = nil;
        if (failure) failure(error);
    }];
    [operation setUploadProgressBlock:^(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            self.progress = (float)totalBytesWritten / (float)totalBytesExpectedToWrite;
        });
    }];
    _uploadOperation = [operation retain];
    self.remoteStatus = MediaRemoteStatusPushing;
    [self.blog.api enqueueHTTPRequestOperation:operation];
}

- (NSString *)html {
	NSString *result = @"";
	
	if(self.mediaType != nil) {
		if([self.mediaType isEqualToString:@"image"]) {
			if(self.shortcode != nil)
				result = self.shortcode;
			else if(self.remoteURL != nil) {
                NSString *linkType = [self.blog getOptionValue:@"image_default_link_type"];
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
    CGSize newSize;
    switch (size) {
        case kResizeSmall:
			newSize = CGSizeMake(150, 150);
            break;
        case kResizeMedium:
            newSize = CGSizeMake(300, 300);
            break;
        case kResizeLarge:
            newSize = CGSizeMake(1200, 1200);
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
