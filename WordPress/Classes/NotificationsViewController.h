//
//  NotificationsViewController.h
//  WordPress
//
//  Created by Beau Collins on 11/05/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NotificationsTableViewDatasource.h"
#import "WPTableViewController.h"

@interface NotificationsViewController : WPTableViewController <DetailViewDelegate>

@property (nonatomic, strong) IBOutlet UIBarButtonItem *settingsButton;

-(void)refreshFromPushNotification;

@end
