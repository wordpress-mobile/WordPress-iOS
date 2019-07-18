#import <UIKit/UIKit.h>

@class Blog;
@class TimeZoneObserver;

@interface SiteSettingsViewController : UITableViewController

@property (nonatomic, strong,  readonly) Blog *blog;
@property (nonatomic, strong) TimeZoneObserver *timeZoneObserver;

- (instancetype)initWithBlog:(Blog *)blog;

- (void)saveSettings;

@end
