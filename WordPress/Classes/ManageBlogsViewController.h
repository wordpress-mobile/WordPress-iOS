//
//  ManageBlogsViewController.h
//  WordPress
//
//  Created by Jorge Bernal on 27/11/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WPAccount.h"

/**
 An interface to manage which blogs are visible for a given account
 */
@interface ManageBlogsViewController : UITableViewController
- (id)initWithAccount:(WPAccount *)account;
@end
