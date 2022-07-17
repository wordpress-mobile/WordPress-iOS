#import <UIKit/UIKit.h>

typedef NS_CLOSED_ENUM(NSUInteger, SuggestionType) {
    SuggestionTypeMention,
    SuggestionTypeXpost
};

@protocol SuggestionsListViewModelType;
@protocol SuggestionsTableViewDelegate;

@interface SuggestionsTableView : UIView

@property (nonatomic, nonnull, strong, readonly) id <SuggestionsListViewModelType> viewModel;
@property (nonatomic, nullable, weak) id <SuggestionsTableViewDelegate> suggestionsDelegate;
@property (nonatomic, nullable, strong) NSArray<NSNumber *> *prominentSuggestionsIds;
@property (nonatomic) BOOL useTransparentHeader;
@property (nonatomic) BOOL animateWithKeyboard;
@property (nonatomic) BOOL showLoading;

- (nonnull instancetype)initWithSiteID:(NSNumber *_Nullable)siteID
                        suggestionType:(SuggestionType)suggestionType
                              delegate:(id <SuggestionsTableViewDelegate>_Nonnull)suggestionsDelegate;

- (nonnull instancetype) initWithViewModel:(id <SuggestionsListViewModelType>_Nonnull)viewModel
                                  delegate:(id <SuggestionsTableViewDelegate>_Nonnull)suggestionsDelegate;

/**
  Enables or disables the SuggestionsTableView component.
 */
@property (nonatomic, assign) BOOL enabled;

/**
  Whether the SuggestionsTableView header subview should have a clear background
 */
- (void)setUseTransparentHeader:(BOOL)useTransparentHeader;

- (void)hideSuggestions;

/// Select the suggestion at a certain position and triggers the selection delegate
/// @param indexPath the index to select
- (void)selectSuggestionAtIndexPath:(NSIndexPath * _Nonnull)indexPath;

/// Show suggestions for the given word.
/// @param word Used to find the suggestions that contain this word.
- (BOOL)showSuggestionsForWord:(nonnull NSString *)string;

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
- (int)suggestionsTableViewMaxDisplayedRows:(nonnull SuggestionsTableView *)suggestionsTableView;

/// This method is called every the header view above the suggestion is tapped.
/// @param suggestionsTableView the suggestion view.
- (void)suggestionsTableViewDidTapHeader:(nonnull SuggestionsTableView *)suggestionsTableView;

/// This method returns the header view minimum height.
/// Can be used as a hit area for the user to dismiss the suggestions list.
/// @param suggestionsTableView the suggestion view.
- (CGFloat)suggestionsTableViewHeaderMinimumHeight:(nonnull SuggestionsTableView *)suggestionsTableView;


@end
