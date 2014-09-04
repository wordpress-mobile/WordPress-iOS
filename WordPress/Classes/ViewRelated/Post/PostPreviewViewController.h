#import <UIKit/UIKit.h>
#import "WPPostViewController.h"

@interface PostPreviewViewController : UIViewController <UIWebViewDelegate>

- (instancetype)initWithPost:(AbstractPost *)aPost;

@end
