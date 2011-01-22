#import <UIKit/UIKit.h>
#import "EditPostViewController.h"

@interface PostPreviewViewController : UIViewController <UIWebViewDelegate> {
    IBOutlet UIWebView *webView;
    BOOL isWebRefreshRequested;

    EditPostViewController *postDetailViewController;
}

@property (nonatomic, assign) EditPostViewController *postDetailViewController;
@property (readonly) UIWebView *webView;

- (void)refreshWebView;
- (void)stopLoading;

@end
