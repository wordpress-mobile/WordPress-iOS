#import <UIKit/UIKit.h>
#import "EditPostViewController.h"

@interface PostPreviewViewController : UIViewController <UIWebViewDelegate>

- (instancetype)initWithPost:(AbstractPost *)aPost;

@end
