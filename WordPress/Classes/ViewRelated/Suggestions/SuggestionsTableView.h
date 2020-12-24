#import <UIKit/UIKit.h>

typedef NS_CLOSED_ENUM(NSUInteger, SuggestionType) {
    SuggestionTypeMention,
    SuggestionTypeXpost
};

@protocol SuggestionsTableViewDelegate;

@interface SuggestionsTableView : UIView <UITableViewDataSource>

@property (nonatomic, nullable, weak) id <SuggestionsTableViewDelegate> suggestionsDelegate;
@property (nonatomic, nullable, strong) NSNumber *siteID;
@property (nonatomic, assign) SuggestionType suggestionType;
@property (nonatomic, nonnull, strong) NSMutableArray *searchResults;
@property (nonatomic, nullable, strong) NSArray *suggestions;
@property (nonatomic, nonnull, strong) NSString *searchText;
@property (nonatomic) BOOL useTransparentHeader;
@property (nonatomic) BOOL animateWithKeyboard;
@property (nonatomic) BOOL showLoading;

- (nonnull instancetype)initWithSiteID:(NSNumber *_Nullable)siteID
                         suggestionType:(SuggestionType)suggestionType
                               delegate:(id <SuggestionsTableViewDelegate>_Nonnull)suggestionsDelegate;

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
- (BOOL)showSuggestionsForWord:(nonnull NSString *)word;

- (void)hideSuggestions;

/// Tells the number of suggestions available for the current search
- (NSInteger)numberOfSuggestions;

/// Select the suggestion at a certain position and triggers the selection delegate
/// @param position the index to select
- (void)selectSuggestionAtPosition:(NSInteger)position;

@end

@protocol SuggestionsTableViewDelegate <NSObject>

@optional

/**
  If the user picks a suggestion from the SuggestionsTableView, the SuggestionsTableView
  will call this method to have the UIViewController prompt the appropriate child
  to replace the search term with the suggestion (e.g. at the caret)
*/
- (void)suggestionsTableView:(nonnull SuggestionsTableView *)suggestionsTableView didSelectSuggestion:(nullable NSString *)suggestion forSearchText:(nonnull NSString *)text;

/**
  When the suggestionsTableView has completed subview layout, the SuggestionsTableView
  will call this method to let the UIViewController know
 */
- (void)suggestionsTableView:(nonnull SuggestionsTableView *)suggestionsTableView didChangeTableBounds:(CGRect)bounds;


/**
  When the suggestionsTableView has completed subview layout, the SuggestionsTableView
  will call this method to let the UIViewController know
 */
- (NSInteger)suggestionsTableViewMaxDisplayedRows:(nonnull SuggestionsTableView *)suggestionsTableView;

/// This method is called every the header view above the suggestion is tapped.
/// @param suggestionsTableView the suggestion view.
- (void)suggestionsTableViewDidTapHeader:(nonnull SuggestionsTableView *)suggestionsTableView;

/// This method returns the header view minimum height.
/// Can be used as a hit area for the user to dismiss the suggestions list.
/// @param suggestionsTableView the suggestion view.
- (CGFloat)suggestionsTableViewHeaderMinimumHeight:(nonnull SuggestionsTableView *)suggestionsTableView;


@end
