//
//  NotificationSettingsViewController.h
//  WordPress
//
//  Created by Dan Roundhill on 12/10/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NotificationSettingsViewController : UITableViewController

@property (nonatomic, strong) NSArray *notificationPrefArray;
@property (nonatomic, strong) NSMutableDictionary *notificationPreferences;

- (void)notificationSettingChanged:(id)sender;
- (void)getNotificationSettings;
- (void)reloadNotificationSettings;

@end
