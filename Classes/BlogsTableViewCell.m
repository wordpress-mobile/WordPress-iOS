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
@implementation BlogsTableViewCell


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
