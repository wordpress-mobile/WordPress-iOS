//
//  WelcomeViewController.h
//  WordPress
//
//  Created by Dan Roundhill on 5/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QuartzCore/QuartzCore.h"
#import "BlogsViewController.h"
#import "WebSignupViewController.h"
#import "AddUsersBlogsViewController.h"
#import "EditBlogViewController.h"
#import "BlogDataManager.h"

@interface WelcomeViewController : UIViewController<UITableViewDelegate> {
	IBOutlet UITableView *tableView;
}

@property (nonatomic, retain) IBOutlet UITableView *tableView;

@end
