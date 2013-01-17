//
//  NotificationsFollowTableViewCell.h
//  WordPress
//
//  Created by Dan Roundhill on 12/4/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NotificationsFollowTableViewCell : UITableViewCell

@property (nonatomic, strong) UIButton *followButton;

- (void)setFollowing: (BOOL)isFollowing;

@end


