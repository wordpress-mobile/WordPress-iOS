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
#import "ContextManager.h"

@interface Media (PrivateMethods)

- (void)xmlrpcUploadWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)xmlrpcDeleteWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)xmlrpcUpdateWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;

@end

@implementation Media {
    AFHTTPRequestOperation *_uploadOperation;
}

@dynamic mediaID;
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
@dynamic caption;
@dynamic desc;
@dynamic mediaTypeString;

@synthesize unattached;

+ (Media *)newMediaForPost:(AbstractPost *)post {
    Media *media = [NSEntityDescription insertNewObjectForEntityForName:@"Media" inManagedObjectContext:post.managedObjectContext];
    media.blog = post.blog;
    media.posts = [NSMutableSet setWithObject:post];
    media.mediaID = @0;
    return media;
}

+ (Media *)newMediaForBlog:(Blog *)blog {
    Media *media = [NSEntityDescription insertNewObjectForEntityForName:@"Media" inManagedObjectContext:blog.managedObjectContext];
    media.blog = blog;
    media.mediaID = @0;
    return media;
}

+ (Media *)createOrReplaceMediaFromJSON:(NSDictionary *)json forBlog:(Blog *)blog {
    NSSet *existing = [blog.media filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"mediaID == %@", [json[@"attachment_id"] numericValue]]];
    if (existing.count > 0) {
        [existing.allObjects[0] updateFromDictionary:json];
        return existing.allObjects[0];
    }
    
    Media *media = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(self.class) inManagedObjectContext:blog.managedObjectContext];
    [media updateFromDictionary:json];
    media.blog = blog;
    return media;
}

+ (void)mergeNewMedia:(NSArray *)media forBlog:(Blog *)blog {
    if ([blog isDeleted] || blog.managedObjectContext == nil)
        return;
    
    NSManagedObjectContext *backgroundMOC = [[ContextManager sharedInstance] backgroundContext];
    [backgroundMOC performBlock:^{
        Blog *contextBlog = (Blog *)[backgroundMOC objectWithID:blog.objectID];
        NSMutableArray *mediaToKeep = [NSMutableArray array];
        for (NSDictionary *item in media) {
            Media *media = [Media createOrReplaceMediaFromJSON:item forBlog:contextBlog];
            [mediaToKeep addObject:media];
        }
        NSSet *syncedMedia = contextBlog.media;
        if (syncedMedia && (syncedMedia.count > 0)) {
            for (Media *m in syncedMedia) {
                if (![mediaToKeep containsObject:m] && m.remoteURL != nil) {
                    DDLogVerbose(@"Deleting media %@", m);
                    [backgroundMOC deleteObject:m];
                }
            }
        }
        
        [[ContextManager sharedInstance] saveContext:backgroundMOC];
    }];
}

- (void)updateFromDictionary:(NSDictionary*)json {
    self.remoteURL = json[@"link"];
    self.title = json[@"title"];
    self.width = [json numberForKeyPath:@"metadata.width"];
    self.height = [json numberForKeyPath:@"metadata.height"];
    self.mediaID = [json numberForKey:@"attachment_id"];
    self.filename = [[json objectForKeyPath:@"metadata.file"] lastPathComponent];
    self.creationDate = json[@"date_created_gmt"];
    self.caption = json[@"caption"];
    self.desc = json[@"description"];
    
    [self mediaTypeFromUrl:[json[@"link"] pathExtension]];
}

- (NSDictionary*)XMLRPCDictionaryForUpdate {
    return @{@"post_title": self.title ? self.title : @"",
             @"post_content": self.desc ? self.desc : @"",
             @"post_excerpt": self.caption ? self.caption : @""};
}

- (void)mediaTypeFromUrl:(NSString *)ext {
    CFStringRef fileExt = (__bridge CFStringRef)ext;
    CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExt, nil);
    CFStringRef ppt = (__bridge CFStringRef)@"public.presentation";
    
    if (UTTypeConformsTo(fileUTI, kUTTypeImage)) {
        self.mediaTypeString = @"image";
    } else if (UTTypeConformsTo(fileUTI, kUTTypeVideo)) {
        self.mediaTypeString = @"video";
    } else if (UTTypeConformsTo(fileUTI, kUTTypeMovie)) {
        self.mediaTypeString = @"video";
    } else if (UTTypeConformsTo(fileUTI, kUTTypeMPEG4)) {
        self.mediaTypeString = @"video";
    } else if (UTTypeConformsTo(fileUTI, ppt)) {
        self.mediaTypeString = @"powerpoint";
    } else {
        self.mediaTypeString = @"document";
    }
}

- (MediaType)mediaType {
    if ([self.mediaTypeString isEqualToString:@"image"]) {
        return MediaTypeImage;
    } else if ([self.mediaTypeString isEqualToString:@"video"]) {
        return MediaTypeVideo;
    } else if ([self.mediaTypeString isEqualToString:@"powerpoint"]) {
        return MediaTypePowerpoint;
    } else if ([self.mediaTypeString isEqualToString:@"document"]) {
        return MediaTypeDocument;
    } else if ([self.mediaTypeString isEqualToString:@"featured"]) {
        return MediaTypeFeatured;
    }
    return MediaTypeDocument;
}

- (void)setMediaType:(MediaType)mediaType {
    switch (mediaType) {
        case MediaTypeImage:
            self.mediaTypeString = @"image";
            break;
        case MediaTypeFeatured:
            self.mediaTypeString = @"featured";
            break;
        case MediaTypeVideo:
            self.mediaTypeString = @"video";
            break;
        case MediaTypePowerpoint:
            self.mediaTypeString = @"powerpoint";
            break;
        case MediaTypeDocument:
        default:
            self.mediaTypeString = @"document";
            break;
    }
}

- (NSString *)mediaTypeName {
    if (self.mediaType == MediaTypeImage) {
        return NSLocalizedString(@"Image", @"");
    } else if (self.mediaType == MediaTypeVideo) {
        return NSLocalizedString(@"Video", @"");
    } else {
        return self.mediaTypeString;
    }
}

- (BOOL)featured {
    return self.mediaType == MediaTypeFeatured;
}

- (void)setFeatured:(BOOL)featured {
    self.mediaType = featured ? MediaTypeFeatured : MediaTypeImage;
}

+ (NSString *)mediaTypeForFeaturedImage {
    return @"image";
}

+ (void)bulkDeleteMedia:(NSArray *)media withSuccess:(void(^)())success failure:(void (^)(NSError *error, NSArray *failures))failure {
    __block NSMutableArray *failedDeletes = [NSMutableArray array];
    for (NSUInteger i = 0; i < media.count; i++) {
        Media *m = media[i];
        // Delete locally if it was never uploaded
        if (!m.remoteURL) {
            [m.managedObjectContext deleteObject:m];
            if (i == media.count-1) {
                if (success) {
                    success();
                }
                return;
            }
            continue;
        }
        
        [m xmlrpcDeleteWithSuccess:^{
            if (i == media.count-1) {
                if (success) {
                    success();
                }
            }
        } failure:^(NSError *error) {
            [failedDeletes addObject:m];
            if (i == media.count-1) {
                if (failure) {
                    failure(error, failedDeletes);
                }
            }
        }];
    }
}

#pragma mark - NSManagedObject subclass methods
- (void)awakeFromFetch {
    [super awakeFromFetch];
	if ((self.remoteStatus == MediaRemoteStatusPushing && _uploadOperation == nil) || (self.remoteStatus == MediaRemoteStatusProcessing) || self.remoteStatus == MediaRemoteStatusFailed) {
        self.remoteStatus = MediaRemoteStatusFailed;
    } else {
        self.remoteStatus = MediaRemoteStatusSync;
    }
}

- (void)didTurnIntoFault {
    [super didTurnIntoFault];
    
    [_uploadOperation cancel];
    _uploadOperation = nil;
}

#pragma mark -

- (CGFloat)progress {
    [self willAccessValueForKey:@"progress"];
    NSNumber *result = [self primitiveValueForKey:@"progress"];
    [self didAccessValueForKey:@"progress"];
    return [result floatValue];
}

- (void)setProgress:(CGFloat)progress {
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
    
    [self.managedObjectContext performBlockAndWait:^{
        [self.managedObjectContext deleteObject:self];
        [self.managedObjectContext save:nil];
    }];
}


- (void)save {
    [self.managedObjectContext performBlock:^{
        [self.managedObjectContext save:nil];
    }];
}

- (BOOL)unattached {
    return self.posts.count == 0;
}

- (void)cancelUpload {
    if ((self.remoteStatus == MediaRemoteStatusPushing || self.remoteStatus == MediaRemoteStatusProcessing) && self.progress < 1.0f) {
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

- (void)remoteUpdateWithSuccess:(void (^)())success failure:(void (^)(NSError *))failure {
    [self save];
    [self xmlrpcUpdateWithSuccess:success failure:failure];
}

- (void)xmlrpcUploadWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure {
    NSString *mimeType = (self.mediaType == MediaTypeVideo) ? @"video/mp4" : @"image/jpeg";
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
            void (^failureBlock)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error) {
                if ([self isDeleted] || self.managedObjectContext == nil) {
                    return;
                }

                self.remoteStatus = MediaRemoteStatusFailed;
                _uploadOperation = nil;
                if (failure) {
                    failure(error);
                }
            };
            AFHTTPRequestOperation *operation = [self.blog.api HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
                if ([self isDeleted] || self.managedObjectContext == nil)
                    return;

                NSDictionary *response = (NSDictionary *)responseObject;

                if (![response isKindOfClass:[NSDictionary class]]) {
                    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"The server returned an empty response. This usually means you need to increase the memory limit for your site.", @"")}];
                    failureBlock(operation, error);
                    return;
                }
                if([response objectForKey:@"videopress_shortcode"] != nil)
                    self.shortcode = [response objectForKey:@"videopress_shortcode"];

                if([response objectForKey:@"url"] != nil)
                    self.remoteURL = [response objectForKey:@"url"];
                
                if ([response objectForKey:@"id"] != nil) {
                    self.mediaID = [[response objectForKey:@"id"] numericValue];
                }

                self.remoteStatus = MediaRemoteStatusSync;
                 _uploadOperation = nil;
                if (success) {
                    success();
                }
            } failure:failureBlock];
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

- (void)xmlrpcDeleteWithSuccess:(void (^)())success failure:(void (^)(NSError *))failure {
    WPXMLRPCRequest *deleteRequest = [self.blog.api XMLRPCRequestWithMethod:@"wp.deletePost" parameters:[self.blog getXMLRPCArgsWithExtra:self.mediaID]];
    WPXMLRPCRequestOperation *deleteOperation = [self.blog.api XMLRPCRequestOperationWithRequest:deleteRequest success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self.managedObjectContext deleteObject:self];
        if (success) {
            success();
        }
        [self.managedObjectContext save:nil];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
    [self.blog.api enqueueXMLRPCRequestOperation:deleteOperation];
}

- (void)xmlrpcUpdateWithSuccess:(void (^)())success failure:(void (^)(NSError *))failure {
    NSArray *params = [self.blog getXMLRPCArgsWithExtra:@[self.mediaID, [self XMLRPCDictionaryForUpdate]]];
    WPXMLRPCRequest *updateRequest = [self.blog.api XMLRPCRequestWithMethod:@"wp.editPost" parameters:params];
    WPXMLRPCRequestOperation *update = [self.blog.api XMLRPCRequestOperationWithRequest:updateRequest success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
    [self.blog.api enqueueXMLRPCRequestOperation:update];
}

- (NSString *)html {
	NSString *result = @"";
    if (self.mediaType == MediaTypeImage) {
        if (self.shortcode != nil) {
            result = self.shortcode;
        } else if(self.remoteURL != nil) {
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
    } else if (self.mediaType == MediaTypeVideo) {
        NSString *embedWidth = [NSString stringWithFormat:@"%@", self.width];
        NSString *embedHeight= [NSString stringWithFormat:@"%@", self.height];
        
        // Check for landscape resize
        if (([self.width intValue] > [self.height intValue]) && ([self.width intValue] > 640)) {
            embedWidth = @"640";
            embedHeight = @"360";
        } else if(([self.height intValue] > [self.width intValue]) && ([self.height intValue] > 640)) {
            embedHeight = @"640";
            embedWidth = @"360";
        }
        
        if (self.shortcode != nil) {
            result = self.shortcode;
        } else if (self.remoteURL != nil) {
            self.remoteURL = [self.remoteURL stringByReplacingOccurrencesOfString:@"\"" withString:@""];
            NSNumber *htmlPreference = [NSNumber numberWithInt:
                                        [[[NSUserDefaults standardUserDefaults] 
                                          objectForKey:@"video_html_preference"] intValue]];
            
            if ([htmlPreference intValue] == 0) {
                // Use HTML 5 <video> tag
                result = [NSString stringWithFormat:
                          @"<video src=\"%@\" controls=\"controls\" width=\"%@\" height=\"%@\">"
                          "Your browser does not support the video tag"
                          "</video>",
                          self.remoteURL, 
                          embedWidth, 
                          embedHeight];
            } else {
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
            
            DDLogVerbose(@"media.html: %@", result);
        }
    }
	return result;
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
        case MediaResizeSmall:
			newSize = smallSize;
            break;
        case MediaResizeMedium:
            newSize = mediumSize;
            break;
        case MediaResizeLarge:
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
	self.filesize = [NSNumber numberWithUnsignedInteger:(imageData.length/1024)];
	self.mediaType = @"image";
	self.thumbnail = UIImageJPEGRepresentation(imageThumbnail, 0.90);
	self.width = [NSNumber numberWithInt:resizedImage.size.width];
	self.height = [NSNumber numberWithInt:resizedImage.size.height];
}

@end
