#import <UIKit/UIKit.h>
#import "PostViewController.h"

@interface PostPreviewViewController : UIViewController <UIWebViewDelegate> {
    IBOutlet UIWebView *webView;
    BOOL isWebRefreshRequested;

    PostViewController *postDetailViewController;
}

@property (nonatomic, retain) NSString *postContent; //fix for #645
@property (nonatomic, assign) PostViewController *postDetailViewController;
@property (readonly) UIWebView *webView;

- (void)refreshWebView;
- (void)setUpdatedPostDescription:(NSString *)surString; //fix for #645
- (void)stopLoading;

@end
