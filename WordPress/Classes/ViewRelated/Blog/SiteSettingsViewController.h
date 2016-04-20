#import <UIKit/UIKit.h>

@class Blog;

@interface SiteSettingsViewController : UITableViewController

@property (nonatomic, assign, readwrite) BOOL isCancellable;
@property (nonatomic, strong,  readonly) Blog *blog;

- (instancetype)initWithBlog:(Blog *)blog;

@end
