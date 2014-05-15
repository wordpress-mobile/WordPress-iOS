#import <UIKit/UIKit.h>
#import "WordPressAppDelegate.h"
#import "UITableViewTextFieldCell.h"
#import "Blog+Jetpack.h"
#import "SettingsViewControllerDelegate.h"

@class Blog;

@interface EditSiteViewController : UIViewController <UITableViewDelegate, UITextFieldDelegate, UIAlertViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) UIBarButtonItem *saveButton;
@property (nonatomic, weak) id<SettingsViewControllerDelegate> delegate;
@property (nonatomic, assign) BOOL isCancellable;
@property (nonatomic, strong) NSString *blogId;
@property (nonatomic, strong) NSArray *subsites;
@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) NSString *password, *username, *url;
@property (nonatomic, assign) BOOL geolocationEnabled;
@property (nonatomic, assign) BOOL isSiteDotCom;

- (id)initWithBlog:(Blog *)blog;

@end
