//
//  WPTableViewController.h
//  WordPress
//
//  Created by Brad Angelcyk on 5/22/12.
//

#import <UIKit/UIKit.h>
#import "Blog.h"
#import "SettingsViewControllerDelegate.h"

@interface WPTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UIAlertViewDelegate, SettingsViewControllerDelegate>

@property (nonatomic, strong) Blog *blog;
@property (nonatomic, readonly) BOOL isScrolling;
@property (nonatomic) BOOL incrementalLoadingSupported;

- (void)promptForPassword;
- (NSString *)noResultsText;

extern CGFloat const WPTableViewTopMargin;

@end
