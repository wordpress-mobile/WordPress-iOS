//
//  AddUsersBlogsViewController.h
//  WordPress
//
//  Created by Chris Boyd on 7/19/10.
//

#import <UIKit/UIKit.h>
#import "WordPressAppDelegate.h"
#import "Blog.h"
#import "WPcomLoginViewController.h"

@class WPAccount;

@interface AddUsersBlogsViewController : UIViewController <UITableViewDelegate> {
	WordPressAppDelegate *appDelegate;
	BOOL hasCompletedGetUsersBlogs, isWPcom;
	NSArray *usersBlogs;
	NSMutableArray *selectedBlogs;
	IBOutlet UITableView *tableView;
	IBOutlet UIBarButtonItem *buttonAddSelected, *buttonSelectAll, *topAddSelectedButton;
}

@property (nonatomic, assign) BOOL hideBackButton;
@property (nonatomic, assign) BOOL hasCompletedGetUsersBlogs, isWPcom;
@property (nonatomic, strong) NSArray *usersBlogs;
@property (nonatomic, strong) NSMutableArray *selectedBlogs;
@property (nonatomic, strong) NSString *username, *url, *password;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *buttonAddSelected, *buttonSelectAll, *topAddSelectedButton;
@property (nonatomic, assign) BOOL geolocationEnabled;

- (AddUsersBlogsViewController *)initWithAccount:(WPAccount *)account;

- (IBAction)selectAllBlogs:(id)sender;
- (IBAction)deselectAllBlogs:(id)sender;
- (void)refreshBlogs;
- (IBAction)saveSelectedBlogs:(id)sender;
- (void)saveSelectedBlogs;
- (void)checkAddSelectedButtonStatus;

@end
