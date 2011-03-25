//
//  BlogsTableViewCell.m
//  WordPress
//
//  Created by Dan Roundhill on 3/24/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "BlogsTableViewCell.h"
#import "QuartzCore/QuartzCore.h"

#define MARGIN 10;

@interface BlogsTableViewCell (Private)
- (void)blavatarLoaded:(NSNotification *)notification;
@end

@implementation BlogsTableViewCell

- (void) addBlavatarNotificationSender:(id)sender {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(blavatarLoaded:) name:BlavatarLoaded object:sender];
}
 
- (void)blavatarLoaded:(NSNotification *)notification {
		NSDictionary *info  = (NSDictionary *)[notification userInfo];
		if( (info != nil) && ([info objectForKey:@"hostURL"] != nil)
		   && [self.detailTextLabel.text isEqualToString:[info objectForKey:@"hostURL"]]) {
			self.image = [info objectForKey:@"faviconImage"];
			[self setNeedsDisplay];
		}
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}


- (void) layoutSubviews {
    [super layoutSubviews];
	CGRect cvf = self.contentView.frame;
    self.imageView.frame = CGRectMake(6,
                                      6,
                                      32,
                                      32);
	self.imageView.layer.cornerRadius = 4.0;
	self.imageView.layer.masksToBounds = YES;
	
	CGRect frame = CGRectMake(cvf.size.height,
                              self.textLabel.frame.origin.y,
                              cvf.size.width - cvf.size.height - 2 * 10,
                              self.textLabel.frame.size.height);
    self.textLabel.frame = frame;
	
    frame = CGRectMake(cvf.size.height,
                       self.detailTextLabel.frame.origin.y,
                       cvf.size.width - cvf.size.height - 2*10,
                       self.detailTextLabel.frame.size.height);   
    self.detailTextLabel.frame = frame;
}


@end
