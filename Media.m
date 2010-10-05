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
			if(self.shortcode != nil)
				result = self.shortcode;
			else if(self.remoteURL != nil)
				result = [NSString stringWithFormat:@"<object width=\"%@\" height=\"%@\""
						  "classid=\"clsid:02BF25D5-8C17-4B23-BC80-D3488ABDDC6B\""
						  "codebase=\"http://www.apple.com/qtactivex/qtplugin.cab\">"
						  "<param name=\"src\" value=\"%@\">"
						  "<param name=\"autoplay\" value=\"false\">"
						  "<param name=\"controller\" value=\"true\">"
						  "<embed src=\"%@\" width=\"%@\" height=\"%@\""
						  "autoplay=\"false\" controller=\"true\" type=\"video/quicktime\""
						  "pluginspage=\"http://www.apple.com/quicktime/download/\">"
						  "</embed></object>",
						 self. width, self.height, self.remoteURL, self.remoteURL, self.width, self.height];
		}
	}
	
	return result;
}

@end
