#import <UIKit/UIKit.h>
#import "EditPostViewController.h"

@interface PostPreviewViewController : UIViewController <UIWebViewDelegate> {
    IBOutlet UIWebView *webView;
    UIView *loadingView;

    EditPostViewController *postDetailViewController;
	NSFetchedResultsController *resultsController;
	
	NSMutableData *receivedData;
}

@property (nonatomic, assign) EditPostViewController *postDetailViewController;
@property (readonly) UIWebView *webView;

- (void)refreshWebView;

@end
