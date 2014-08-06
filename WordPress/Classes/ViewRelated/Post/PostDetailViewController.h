#import <UIKit/UIKit.h>

extern NSString *const WPPostDetailNavigationRestorationID;

@class AbstractPost;

@interface PostDetailViewController : UIViewController

- (instancetype)initWithPost:(AbstractPost *)aPost;

@end
