#import <UIKit/UIKit.h>
#import "WPTextFieldTableViewCell.h"
#import "SettingsViewControllerDelegate.h"

@class Blog;

@interface EditSiteViewController : UITableViewController

@property (nonatomic,   weak, readwrite) id<SettingsViewControllerDelegate> delegate;
@property (nonatomic, assign, readwrite) BOOL isCancellable;
@property (nonatomic, strong,  readonly) Blog *blog;

- (instancetype)initWithBlog:(Blog *)blog;

@end
