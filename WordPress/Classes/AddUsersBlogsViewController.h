//
//  AddUsersBlogsViewController.h
//  WordPress
//
//  Created by Chris Boyd on 7/19/10.
//

#import <UIKit/UIKit.h>
#import "WordPressAppDelegate.h"
#import "Blog.h"
#import "WPProgressHUD.h"
#import "WPcomLoginViewController.h"

@interface AddUsersBlogsViewController : UIViewController <UITableViewDelegate> {
	WordPressAppDelegate *appDelegate;
	BOOL hasCompletedGetUsersBlogs, isWPcom;
	NSArray *usersBlogs;
	NSMutableArray *selectedBlogs;
	IBOutlet UITableView *tableView;
	IBOutlet UIBarButtonItem *buttonAddSelected, *buttonSelectAll, *topAddSelectedButton;
	WPProgressHUD *spinner;
}

@property (nonatomic, assign) BOOL hasCompletedGetUsersBlogs, isWPcom;
@property (nonatomic, strong) NSArray *usersBlogs;
@property (nonatomic, strong) NSMutableArray *selectedBlogs;
@property (nonatomic, strong) NSString *username, *url, *password;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *buttonAddSelected, *buttonSelectAll, *topAddSelectedButton;
@property (nonatomic, strong) WPProgressHUD *spinner;
@property (nonatomic, assign) BOOL geolocationEnabled;

- (IBAction)selectAllBlogs:(id)sender;
- (IBAction)deselectAllBlogs:(id)sender;
- (void)refreshBlogs;
- (IBAction)saveSelectedBlogs:(id)sender;
- (void)createBlog:(NSDictionary *)blogInfo;
- (void)cancelAddWPcomBlogs;
- (void)saveSelectedBlogs;
- (void)didSaveSelectedBlogsInBackground;
- (void)signOut;
- (void)checkAddSelectedButtonStatus;

@end
