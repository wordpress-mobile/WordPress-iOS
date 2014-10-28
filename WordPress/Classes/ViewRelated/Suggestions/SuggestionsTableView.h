#import <UIKit/UIKit.h>

@protocol SuggestionsTableViewDelegate;

@interface SuggestionsTableView : UIView <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) id <SuggestionsTableViewDelegate> suggestionsDelegate;

- (instancetype)initWithSiteID:(NSNumber *)siteID;
- (void)showSuggestionsForWord:(NSString *)word;

@end

@protocol SuggestionsTableViewDelegate <NSObject>

@optional

/*
 * Child views (e.g. UITextView) of a UIViewController can call this method on the VC to have the
 * UIViewController update the SuggestionsTableView with appropriate suggestions (if any)
*/
- (void)view:(UIView *)view didTypeInWord:(NSString *)word;

/*
 * If the user picks a suggestion from the SuggestionsTableView, the SuggestionsTableView
 * will call this method to have the UIViewController prompt the appropriate child
 * to replace the search term with the suggestion (e.g. at the caret)
*/
- (void)suggestionsTableView:(SuggestionsTableView *)suggestionsTableView didSelectSuggestion:(NSString *)suggestion forSearchText:(NSString *)text;

@end

@protocol SuggestableView

@optional

/*
 * Child views of a UIViewController should implement this method so the
 * view controller can prompt them to replace recently typed text with the
 * suggested text the user picked
 */
- (void)replaceTextAtCaret:(NSString *)text withSuggestion:(NSString *)suggestion;

@end

