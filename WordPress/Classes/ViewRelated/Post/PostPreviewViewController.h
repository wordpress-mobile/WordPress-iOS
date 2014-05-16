#import <UIKit/UIKit.h>
#import "EditPostViewController.h"

@interface PostPreviewViewController : UIViewController <UIWebViewDelegate>

- (id)initWithPost:(AbstractPost *)aPost;

@end
