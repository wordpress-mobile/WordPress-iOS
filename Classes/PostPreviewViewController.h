#import <UIKit/UIKit.h>
#import "PostViewController.h"

@interface PostPreviewViewController : UIViewController {
    IBOutlet UIWebView *webView;
    BOOL isWebRefreshRequested;

    PostViewController *postDetailViewController;
}

@property (nonatomic, assign) PostViewController *postDetailViewController;
@property (readonly) UIWebView *webView;

- (void)refreshWebView;
- (void)stopLoading;

@end
