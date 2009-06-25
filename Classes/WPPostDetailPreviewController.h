#import <UIKit/UIKit.h>
#import "PostPhotosViewController.h"

@interface WPPostDetailPreviewController : UIViewController {
	IBOutlet UIWebView *webView;
	BOOL isWebRefreshRequested;
	
	PostPhotosViewController *postDetailViewController;
}

@property (nonatomic, assign)PostPhotosViewController * postDetailViewController;
@property (readonly) UIWebView *webView;

- (void)refreshWebView;
- (void)stopLoading;
@end
