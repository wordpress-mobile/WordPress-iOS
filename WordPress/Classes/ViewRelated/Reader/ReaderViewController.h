#import <UIKit/UIKit.h>
#import "WPScrollableViewController.h"

@interface ReaderViewController : UIViewController <WPScrollableViewController>
- (void)openPost:(NSNumber *)postId onBlog:(NSNumber *)blogId;
@end
