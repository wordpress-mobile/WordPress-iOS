//
//  NotificationsFollowTableViewCell.m
//  WordPress
//
//  Created by Dan Roundhill on 12/4/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "NotificationsFollowTableViewCell.h"
#import "FollowButton.h"

@implementation NotificationsFollowTableViewCell

@synthesize actionButton;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [actionButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
        [actionButton setFrame:CGRectMake(100.0f, 20.0f, 80.0f, 30.0f)];
        [actionButton setImageEdgeInsets:UIEdgeInsetsMake(0.0f, 6.0f, 0.0f, 0.0f)];
        [actionButton.titleLabel setFont:[UIFont boldSystemFontOfSize:14.0f]];
        [actionButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, 9.0f, 0.0f, 2.0f)];
        [actionButton.imageView setContentMode:UIViewContentModeLeft];
        [actionButton.titleLabel setTextAlignment:NSTextAlignmentLeft];
        [actionButton.titleLabel setLineBreakMode:UILineBreakModeTailTruncation];
        [self addSubview:actionButton];
        
        [self.textLabel setTextColor:[UIColor UIColorFromHex:0x030303]];
        [self.textLabel setBackgroundColor:[UIColor clearColor]];
        [self.textLabel setFont:[UIFont boldSystemFontOfSize:16.0f]];
        
        [self.detailTextLabel setFont:[UIFont systemFontOfSize:14.0f]];
        [self.detailTextLabel setTextColor:[UIColor UIColorFromHex:0x0074A2]];
        [self.detailTextLabel setBackgroundColor:[UIColor clearColor]];
        [self.detailTextLabel setNumberOfLines:1];
        [self.detailTextLabel setAdjustsFontSizeToFitWidth:NO];
        [self.detailTextLabel setLineBreakMode:UILineBreakModeTailTruncation];
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"cell_gradient_bg"] stretchableImageWithLeftCapWidth:0 topCapHeight:1]];
        [self setBackgroundView:imageView];
    }
    return self;
}

- (void)setFollowing:(BOOL)isFollowing {
    if (isFollowing) {
        [actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [actionButton setImage:[UIImage imageNamed:@"note_button_icon_following"] forState:UIControlStateNormal];
        [actionButton setBackgroundImage:[[UIImage imageNamed:@"navbar_primary_button_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.0f, 4.0f, 0.0f, 4.0f)] forState:UIControlStateNormal];
        [actionButton setBackgroundImage:[[UIImage imageNamed:@"navbar_primary_button_bg_active"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.0f, 4.0f, 0.0f, 4.0f)] forState:UIControlStateHighlighted];
    } else {
        [actionButton setTitleColor:[UIColor UIColorFromHex:0x1A1A1A] forState:UIControlStateNormal];
        [actionButton setImage:[UIImage imageNamed:@"note_button_icon_follow"] forState:UIControlStateNormal];
        [actionButton setBackgroundImage:[[UIImage imageNamed:@"navbar_button_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.0f, 4.0f, 0.0f, 4.0f)] forState:UIControlStateNormal];
        [actionButton setBackgroundImage:[[UIImage imageNamed:@"navbar_button_bg_active"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.0f, 4.0f, 0.0f, 4.0f)] forState:UIControlStateHighlighted];
    }
    CGSize textSize = [[actionButton.titleLabel text] sizeWithFont:[actionButton.titleLabel font]];
    CGFloat buttonWidth = textSize.width + 40.0f;
    if (buttonWidth > 180.0f)
        buttonWidth = 180.0f;
    [actionButton setFrame:CGRectMake(actionButton.frame.origin.x, actionButton.frame.origin.y, buttonWidth, 30.0f)];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.imageView setFrame:CGRectMake(10.0f, 10.0f, 80.0f, 80.0f)];
    [self.textLabel setFrame:CGRectMake(100.0f, 20.0f, 180.0f, 30.0f)];
    [self.detailTextLabel setFrame:CGRectMake(100.0f, 55.0f, self.frame.size.width - 140.0f, 30.0f)];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
