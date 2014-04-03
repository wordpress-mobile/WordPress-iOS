//
//  NotificationsFollowTableViewCell.m
//  WordPress
//
//  Created by Dan Roundhill on 12/4/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "NotificationsFollowTableViewCell.h"

@implementation NotificationsFollowTableViewCell

@synthesize actionButton;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    // Ignore the style argument, override with subtitle style.
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [WPStyleGuide configureFollowButton:actionButton];
        [actionButton setTitleEdgeInsets: UIEdgeInsetsMake(0, 2.0f, 0, 0)];
		[actionButton addTarget:self action:@selector(actionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:actionButton];
        
        [self.textLabel setBackgroundColor:[UIColor clearColor]];
        [self.textLabel setTextColor:[WPStyleGuide littleEddieGrey]];
        [self.textLabel setFont:[WPStyleGuide postTitleFont]];
        [self.textLabel setFont:[WPStyleGuide tableviewSectionHeaderFont]];
		
        [self.detailTextLabel setFont:[WPStyleGuide subtitleFont]];
        [self.detailTextLabel setTextColor:[WPStyleGuide baseDarkerBlue]];
        [self.detailTextLabel setBackgroundColor:[UIColor clearColor]];
        [self.detailTextLabel setNumberOfLines:1];
        [self.detailTextLabel setAdjustsFontSizeToFitWidth:NO];
        [self.detailTextLabel setLineBreakMode:NSLineBreakByTruncatingTail];
    }
	
    return self;
}

- (void)setFollowing:(BOOL)isFollowing
{
    [actionButton setSelected:isFollowing];
	_following = isFollowing;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self.imageView setFrame:CGRectMake(10.0f, 10.0f, 60.0f, 60.0f)];
    [self.textLabel setFrame:CGRectMake(80.0f, 4.0f, 180.0f, 30.0f)];
    [self.detailTextLabel setFrame:CGRectMake(80.0f, 44.0f, self.frame.size.width - 140.0f, 30.0f)];
    [actionButton setFrame:CGRectMake(78.0f, 22.0f, 100.0f, 30.0f)];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    actionButton.highlighted = NO;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    actionButton.highlighted = NO;
}

- (void)actionButtonPressed:(id)sender
{
	if (_onClick) {
		_onClick(self);
	}
}

@end
