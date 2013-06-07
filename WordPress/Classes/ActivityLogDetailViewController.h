//
//  ActivityLogDetailViewController.h
//  WordPress
//
//  Created by Aaron Douglas on 6/7/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ActivityLogDetailViewController : UIViewController

- (id)initWithLog:(NSString *)logText forDateString:(NSDate *)logDate;

@end
