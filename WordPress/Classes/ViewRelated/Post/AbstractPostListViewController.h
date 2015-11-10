#import <UIKit/UIKit.h>

@class Blog;

extern NSString *const WPAppAnalyticsKeyBlogID;

@interface AbstractPostListViewController : UIViewController

@property (nonatomic, strong) Blog *blog;

@end
