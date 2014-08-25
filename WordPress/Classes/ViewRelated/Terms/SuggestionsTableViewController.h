#import <UIKit/UIKit.h>

@protocol SuggestionsTableViewDelegate;

@interface SuggestionsTableViewController : UITableViewController

@property (nonatomic, weak) id<SuggestionsTableViewDelegate> delegate;

@end

@protocol SuggestionsTableViewDelegate <NSObject>

@optional

- (void)suggestionViewDidSelect:(SuggestionsTableViewController *)suggestionsTableViewController
                selectionString:(NSString *)string;

- (void)suggestionViewDidDisappear:(SuggestionsTableViewController *)suggestionsTableViewController;

@end
