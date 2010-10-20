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
						  @"<a href=\"%@\"><img src=\"%@\" alt=\"%@\" class=\"alignnone size-full\" /></a>",
						  self.remoteURL, self.remoteURL, self.caption, self.width, self.height];
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
					result = [NSString stringWithFormat:
							  @"<object classid=\"clsid:02BF25D5-8C17-4B23-BC80-D3488ABDDC6B\""
							  "codebase=\"http://www.apple.com/qtactivex/qtplugin.cab\""
							  "width=\"%@\" height=\"%@\">"
							  "<param name=\"src\" value=\"%@\">"
							  "<embed src=\"%@\""
							  "width=\"%@\" height=\"%@\" type=\"video/quicktime\""
							  "pluginspage=\"http://www.apple.com/quicktime/download/\""
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
