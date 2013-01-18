#import <UIKit/UIKit.h>
#import "EditPostViewController.h"

@interface PostPreviewViewController : UIViewController <UIWebViewDelegate> {
    IBOutlet UIWebView *__weak webView;
    UIView *loadingView;

    EditPostViewController *__weak postDetailViewController;
	NSFetchedResultsController *resultsController;
	
	NSMutableData *receivedData;
}

@property (nonatomic, weak) EditPostViewController *postDetailViewController;
@property (weak, readonly) UIWebView *webView;

- (void)refreshWebView;

@end
