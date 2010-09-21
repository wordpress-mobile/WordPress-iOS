//
//  WelcomeViewController.h
//  WordPress
//
//  Created by Dan Roundhill on 5/5/10.
//

#import <UIKit/UIKit.h>
#import "WordPressAppDelegate.h"
#import "BlogsViewController.h"
#import "WebSignupViewController.h"
#import "AddUsersBlogsViewController.h"
#import "AddSiteViewController.h"
#import "WPcomLoginViewController.h"
#import "EditSiteViewController.h"
#import "BlogDataManager.h"
#import "WordPressAppDelegate.h"

@interface WelcomeViewController : UIViewController<UITableViewDelegate> {
	IBOutlet UITableView *tableView;
	AddSiteViewController *addSiteView;
	WordPressAppDelegate *appDelegate;
}

@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) AddSiteViewController *addSiteView;
@property (nonatomic, assign) WordPressAppDelegate *appDelegate;

- (IBAction)cancel:(id)sender;

@end
