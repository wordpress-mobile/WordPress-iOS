//
//  WPTableViewController.h
//  WordPress
//
//  Created by Brad Angelcyk on 5/22/12.
//

#import <UIKit/UIKit.h>
#import "Blog.h"
#import "SettingsViewControllerDelegate.h"

//@interface WPTableViewController : UITableViewController <NSFetchedResultsControllerDelegate, UIAlertViewDelegate, SettingsViewControllerDelegate>
@interface WPTableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UIAlertViewDelegate, SettingsViewControllerDelegate>

@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, readonly) BOOL isScrolling;
@property (nonatomic) BOOL incrementalLoadingSupported;

- (void)promptForPassword;
- (UIColor *)backgroundColorForRefreshHeaderView;
- (NSString *)noResultsText;

@end
