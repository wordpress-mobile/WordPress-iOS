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
@property (nonatomic, retain) NSArray *usersBlogs;
@property (nonatomic, retain) NSMutableArray *selectedBlogs;
@property (nonatomic, retain) NSString *username, *url, *password;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *buttonAddSelected, *buttonSelectAll, *topAddSelectedButton;
@property (nonatomic, retain) WPProgressHUD *spinner;
@property (nonatomic, assign) BOOL geolocationEnabled;

- (IBAction)selectAllBlogs:(id)sender;
- (IBAction)deselectAllBlogs:(id)sender;
- (void)refreshBlogs;
- (IBAction)saveSelectedBlogs:(id)sender;
- (void)createBlog:(NSDictionary *)blogInfo;
- (void)cancelAddWPcomBlogs;
- (void)didSaveSelectedBlogsInBackground;
- (void)signOut;
- (void)checkAddSelectedButtonStatus;

@end
