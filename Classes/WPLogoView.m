//
//  WPLogoView.m
//  WordPress
//
//  Created by Janakiram on 16/01/09.
//

#import "WPLogoView.h"


@implementation WPLogoView


- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
		self.backgroundColor = [UIColor clearColor];
	}
    return self;
}


- (void)drawRect:(CGRect)rect 
{
	// Drawing code
	UIImage *image = [UIImage imageNamed:@"wplogo.png"];
	CGSize imageSize = image.size ;
	CGRect imageRect = CGRectMake(CGRectGetMidX(rect)-imageSize.width/2, rect.origin.y, imageSize.width, imageSize.height);
	[image drawInRect:imageRect];
}


- (void)dealloc {
    [super dealloc];
}


@end
