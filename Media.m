// 
//  Media.m
//  WordPress
//
//  Created by Chris Boyd on 6/23/10.
//  
//

#import "Media.h"
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
            return @"Uploading";
            break;
        case MediaRemoteStatusFailed:
            return @"Failed";
            break;
        case MediaRemoteStatusSync:
            return @"Uploaded";
            break;
        default:
            return @"Pending";
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
        NSLog(@"Unresolved Core Data Save error %@, %@", error, [error userInfo]);
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

@end
