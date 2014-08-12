#import <UIKit/UIKit.h>
#import "Suggestion.h"

@interface SuggestionsTableViewController : UITableViewController <UISearchBarDelegate, UISearchDisplayDelegate>

@property (nonatomic,weak) id delegate;

@property (nonatomic, strong) UISearchBar *viewSearchBar;
@property (nonatomic, strong) UISearchDisplayController *viewSearchDisplayController;
@property (strong) NSMutableArray *suggestions;
@property (strong) NSMutableArray *searchResults;

@end

@protocol SuggestionsTableViewDelegate <NSObject>

@optional

- (void)suggestionViewDidSelect:(SuggestionsTableViewController *)suggestionsTableViewController
                  selectionString:(NSString *)string;

- (void)suggestionViewDidDisappear:(SuggestionsTableViewController *)suggestionsTableViewController;

@end
