//
//  WPTableViewController.h
//  WordPress
//
//  Created by Brad Angelcyk on 5/22/12.
//

#import <UIKit/UIKit.h>
#import "Blog.h"
#import "SettingsViewControllerDelegate.h"

@interface WPTableViewController : UITableViewController <NSFetchedResultsControllerDelegate, UIAlertViewDelegate,SettingsViewControllerDelegate>

@property (nonatomic, strong) Blog *blog;

@end
