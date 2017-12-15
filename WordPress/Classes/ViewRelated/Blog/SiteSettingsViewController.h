#import <UIKit/UIKit.h>

@class Blog;

@interface SiteSettingsViewController : UITableViewController

@property (nonatomic, strong,  readonly) Blog *blog;

- (instancetype)initWithBlog:(Blog *)blog;

- (void)saveSettings;

@end
