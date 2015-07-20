#import <UIKit/UIKit.h>
#import "UITableViewTextFieldCell.h"
#import "SettingsViewControllerDelegate.h"

@class Blog;

@interface SiteSettingsViewController : UITableViewController

@property (nonatomic,   weak, readwrite) id<SettingsViewControllerDelegate> delegate;
@property (nonatomic, assign, readwrite) BOOL isCancellable;
@property (nonatomic, strong,  readonly) Blog *blog;

- (instancetype)initWithBlog:(Blog *)blog;

@end
