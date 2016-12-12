#import <UIKit/UIKit.h>
#import "WPPostViewController.h"

@interface PostPreviewViewController : UIViewController <UIWebViewDelegate>

/*
 EditPostViewController instance will execute the onClose callback, if provided, whenever the UI is dismissed.
 */
typedef void (^PostPreviewViewCompletionHandler)(void);
@property (nonatomic, copy, readwrite) PostPreviewViewCompletionHandler onClose;

- (instancetype)initWithPost:(AbstractPost *)aPost;

@end
