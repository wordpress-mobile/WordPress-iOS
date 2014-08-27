#import <UIKit/UIKit.h>

@protocol SuggestionsTableViewDelegate;

@interface SuggestionsTableViewController : UITableViewController

@property (nonatomic, weak) id<SuggestionsTableViewDelegate> delegate;

- (instancetype)initWithSiteID:(NSNumber *)siteID;

@end

@protocol SuggestionsTableViewDelegate <NSObject>

@optional

- (void)suggestionTableView:(SuggestionsTableViewController *)suggestionsTableViewController
            didSelectString:(NSString *)string;

- (void)suggestionViewDidDisappear:(SuggestionsTableViewController *)suggestionsTableViewController;

@end
