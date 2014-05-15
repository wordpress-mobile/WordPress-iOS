#import "Blog.h"
#import "SettingsViewControllerDelegate.h"
#import "WPNoResultsView.h"

extern CGFloat const WPTableViewTopMargin;

@interface WPTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, SettingsViewControllerDelegate, WPNoResultsViewDelegate, UIViewControllerRestoration>

@property (nonatomic, strong) Blog *blog;
@property (nonatomic, readonly) BOOL isScrolling;
@property (nonatomic) BOOL incrementalLoadingSupported;

- (void)promptForPassword;
- (NSString *)noResultsTitleText;
- (NSString *)noResultsMessageText;
- (NSString *)noResultsButtonText;
- (UIView *)noResultsAccessoryView;
- (void)configureNoResultsView;

@end
