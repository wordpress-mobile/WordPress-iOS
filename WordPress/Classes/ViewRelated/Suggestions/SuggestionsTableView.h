#import <UIKit/UIKit.h>

@protocol SuggestionsTableViewDelegate;

@interface SuggestionsTableView : UIView <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) id <SuggestionsTableViewDelegate> suggestionsDelegate;
@property (nonatomic) BOOL useTransparentHeader;

- (instancetype)initWithSiteID:(NSNumber *)siteID;


/**
  Enables or disables the SuggestionsTableView component.
 */
@property (nonatomic, assign) BOOL enabled;

/**
  Whether the SuggestionsTableView header subview should have a clear background
 */
- (void)setUseTransparentHeader:(BOOL)useTransparentHeader;

/**
  Show suggestions for the given word - returns YES if at least one suggestion is being shown
*/
- (BOOL)showSuggestionsForWord:(NSString *)word;

@end

@protocol SuggestionsTableViewDelegate <NSObject>

@optional

/**
  If the user picks a suggestion from the SuggestionsTableView, the SuggestionsTableView
  will call this method to have the UIViewController prompt the appropriate child
  to replace the search term with the suggestion (e.g. at the caret)
*/
- (void)suggestionsTableView:(SuggestionsTableView *)suggestionsTableView didSelectSuggestion:(NSString *)suggestion forSearchText:(NSString *)text;

/**
  When the suggestionsTableView has completed subview layout, the SuggestionsTableView
  will call this method to let the UIViewController know
 */
- (void)suggestionsTableView:(SuggestionsTableView *)suggestionsTableView didChangeTableBounds:(CGRect)bounds;

@end
