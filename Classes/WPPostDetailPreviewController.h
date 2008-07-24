#import <UIKit/UIKit.h>
#import "PostDetailViewController.h"

@interface WPPostDetailPreviewController : UIViewController {
	IBOutlet UIWebView *webView;
	BOOL isWebRefreshRequested;
	
	PostDetailViewController *postDetailViewController;
}

@property (nonatomic, assign)PostDetailViewController * postDetailViewController;
@property (readonly) UIWebView *webView;

- (void)refreshWebView;
- (void)stopLoading;
@end
