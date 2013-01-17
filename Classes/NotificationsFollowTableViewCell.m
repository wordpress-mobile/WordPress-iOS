//
//  NotificationsFollowTableViewCell.m
//  WordPress
//
//  Created by Dan Roundhill on 12/4/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "NotificationsFollowTableViewCell.h"

@implementation NotificationsFollowTableViewCell

@synthesize followButton;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        followButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [followButton setFrame:CGRectMake(100.0f, 20.0f, 80, 30)];
        [followButton.titleLabel setFont:[UIFont boldSystemFontOfSize:14.0f]];
        [followButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, 4.0f, 0.0f, 0.0f)];
        [self addSubview:followButton];
        
        [self.textLabel setFont:[UIFont systemFontOfSize:14.0f]];
        [self.textLabel setTextColor:[UIColor UIColorFromHex:0x0074A2]];
        [self.textLabel setBackgroundColor:[UIColor clearColor]];
        [self.textLabel setNumberOfLines:1];
        [self.textLabel setAdjustsFontSizeToFitWidth:NO];
        [self.textLabel setLineBreakMode:UILineBreakModeTailTruncation];
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"cell_gradient_bg"] stretchableImageWithLeftCapWidth:0 topCapHeight:1]];
        [self setBackgroundView:imageView];
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return self;
}

- (void)setFollowing:(BOOL)isFollowing {
    if (isFollowing) {
        [followButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [followButton setImage:[UIImage imageNamed:@"note_following_checkmark"] forState:UIControlStateNormal];
        [followButton setBackgroundImage:[[UIImage imageNamed:@"navbar_primary_button_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.0f, 4.0f, 0.0f, 4.0f)] forState:UIControlStateNormal];
        [followButton setBackgroundImage:[[UIImage imageNamed:@"navbar_primary_button_bg_active"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.0f, 4.0f, 0.0f, 4.0f)] forState:UIControlStateHighlighted];
    } else {
        [followButton setTitleColor:[UIColor UIColorFromHex:0x1A1A1A] forState:UIControlStateNormal];
        [followButton setImage:[UIImage imageNamed:@"note_icon_follow"] forState:UIControlStateNormal];
        [followButton setBackgroundImage:[[UIImage imageNamed:@"navbar_button_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.0f, 4.0f, 0.0f, 4.0f)] forState:UIControlStateNormal];
        [followButton setBackgroundImage:[[UIImage imageNamed:@"navbar_button_bg_active"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.0f, 4.0f, 0.0f, 4.0f)] forState:UIControlStateHighlighted];
        
    }
    
    CGSize textSize = [[followButton.titleLabel text] sizeWithFont:[followButton.titleLabel font]];
    CGFloat buttonWidth = textSize.width + 40.0f;
    if (buttonWidth > 180.0f)
        buttonWidth = 180.0f;
    [followButton setFrame:CGRectMake(followButton.frame.origin.x, followButton.frame.origin.y, buttonWidth, 30.0f)];
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.imageView setFrame:CGRectMake(10.0f, 10.0f, 80.0f, 80.0f)];
    [self.textLabel setFrame:CGRectMake(100.0f, 55.0f, self.frame.size.width - 140.0f, 30.0f)];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
