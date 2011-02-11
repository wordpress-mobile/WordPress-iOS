#import <UIKit/UIKit.h>
#import "EditPostViewController.h"

@interface PostPreviewViewController : UIViewController <UIWebViewDelegate,  NSFetchedResultsControllerDelegate> {
    IBOutlet UIWebView *webView;
    BOOL isWebRefreshRequested;

    EditPostViewController *postDetailViewController;
	NSFetchedResultsController *resultsController;
}

@property (nonatomic, assign) EditPostViewController *postDetailViewController;
@property (readonly) NSFetchedResultsController *resultsController;
@property (readonly) UIWebView *webView;

- (void)refreshWebView;
- (void)stopLoading;

@end
