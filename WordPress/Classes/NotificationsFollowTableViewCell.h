//
//  NotificationsFollowTableViewCell.h
//  WordPress
//
//  Created by Dan Roundhill on 12/4/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^NotificationsFollowBlock)(id sender);

@interface NotificationsFollowTableViewCell : UITableViewCell

@property (nonatomic, copy)	  NotificationsFollowBlock	onClick;
@property (nonatomic, strong) UIButton					*actionButton;
@property (nonatomic, assign) BOOL						following;

@end
