#import <UIKit/UIKit.h>

@class PageDetailViewController;
@interface PagesListController : UIViewController {
	
	IBOutlet UITableView *pagesTableView;
	IBOutlet UIBarButtonItem *postsStatusButton;
	PageDetailViewController *pageDetailViewController;
	BOOL connectionStatus;
}
@property (nonatomic, retain) PageDetailViewController *pageDetailViewController;
- (IBAction)downloadRecentPages:(id)sender;

@end
