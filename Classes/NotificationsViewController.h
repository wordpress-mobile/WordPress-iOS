//
//  NotificationsViewController.h
//  WordPress
//
//  Created by Beau Collins on 11/05/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NotificationsTableViewDatasource.h"

@interface NotificationsViewController : UITableViewController <UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource> {
    @private
    UIActivityIndicatorView *activityFooter;
}

-(void)refreshFromPushNotification;

@end
