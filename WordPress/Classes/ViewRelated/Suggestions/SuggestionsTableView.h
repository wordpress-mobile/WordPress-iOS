#import <UIKit/UIKit.h>

@protocol SuggestionsDelegate <NSObject>

@optional

/*
 * Child views of a UIViewController can call this method to have the
 * UIViewController update the SuggestionsTableView with appropriate suggestions (if any)
*/
- (void)didTypeInWord:(NSString *)word;

/*
 * If the user picks a suggestion from the SuggestionsTableView, the SuggestionsTableView
 * will call this method to have the UIViewController prompt the appropriate child
 * to replace the search term with the suggestion (e.g. at the caret)
*/
- (void)didSelectSuggestion:(NSString *)suggestion forSearchText:(NSString *)text;

@end

@protocol SuggestableView

@optional

/*
 * Child views of a UIViewController should implement this method so the
 * view controller can prompt them to replace recently typed text with the
 * suggested text the user picked
 */
- (void)replaceRecentlyTypedWord:(NSString *)word withSuggestion:(NSString *)suggestion;

@end

@interface SuggestionsTableView : UITableView <UITableViewDataSource>

- (id)initWithWidth:(CGFloat)width andSiteID:(NSNumber *)siteID;
- (void)showSuggestionsForWord:(NSString *)word;

@end
