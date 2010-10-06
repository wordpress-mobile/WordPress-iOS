// 
//  Media.m
//  WordPress
//
//  Created by Chris Boyd on 6/23/10.
//  
//

#import "Media.h"


@implementation Media 

@dynamic mediaType;
@dynamic remoteURL;
@dynamic localURL;
@dynamic shortcode;
@dynamic uniqueID;
@dynamic width;
@dynamic longitude;
@dynamic latitude;
@dynamic length;
@dynamic title;
@dynamic thumbnail;
@dynamic postID;
@dynamic blogID;
@dynamic blogURL;
@dynamic height;
@dynamic filename;
@dynamic filesize;
@dynamic caption;
@dynamic orientation;
@dynamic creationDate;

- (NSString *)html {
	NSString *result = @"";
	
	if(self.mediaType != nil) {
		if([self.mediaType isEqualToString:@"image"]) {
			if(self.caption == nil)
				self.caption = @"";
			
			if(self.shortcode != nil)
				result = self.shortcode;
			else if(self.remoteURL != nil)
				result = [NSString stringWithFormat:
						  @"<img src=\"%@\" alt=\"%@\" width=\"%@\" height=\"%@\" class=\"alignnone size-full\" />",
						  self.remoteURL, self.caption, self.width, self.height];
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
			else if(self.remoteURL != nil)
				result = [NSString stringWithFormat:
						  @"<video src=\"%@\" controls=\"controls\" width=\"%@\" height=\"%@\">"
						  "Your browser does not support the video tag"
						  "</video>",
						  [self.remoteURL stringByReplacingOccurrencesOfString:@"\"" withString:@""], 
						  embedWidth, 
						  embedHeight];
		}
	}
	
	return result;
}

@end
