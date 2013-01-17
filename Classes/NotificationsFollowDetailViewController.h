//
//  NotificationsLikesDetailViewController.h
//  WordPress
//
//  Created by Dan Roundhill on 11/29/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Note.h"

@interface NotificationsFollowDetailViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) Note *note;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UILabel *blogTitleLabel;
@property (nonatomic, strong) IBOutlet UILabel *headerLabel;
@property (nonatomic, strong) IBOutlet UIView *postTitleView;

@end
