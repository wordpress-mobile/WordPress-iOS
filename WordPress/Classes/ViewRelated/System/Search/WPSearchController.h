#import <Foundation/Foundation.h>

/**
 * @class WPSearchController
 * @brief WPSearchController is a stand-in for the iOS 8 UISearchController class.
 * Not all features of UISearchController are implemented.
 * @details Switch to UISearchController when support for < iOS 8 is ended.
 */

@class WPSearchController;

@protocol WPSearchControllerDelegate <NSObject>
@optional
- (void)presentSearchController:(WPSearchController *)searchController;
- (void)willPresentSearchController:(WPSearchController *)searchController;
- (void)didPresentSearchController:(WPSearchController *)searchController;
- (void)willDismissSearchController:(WPSearchController *)searchController;
- (void)didDismissSearchController:(WPSearchController *)searchController;
@end

@protocol WPSearchResultsUpdating <NSObject>
@required
// Called when the search bar's text or scope has changed or when the search bar becomes first responder.
- (void)updateSearchResultsForSearchController:(WPSearchController *)searchController;
@end

@interface WPSearchController : NSObject

@property (nonatomic, weak) id <WPSearchResultsUpdating> searchResultsUpdater; // The object responsible for updating the content of the searchResultsController.
@property (nonatomic, assign, getter = isActive) BOOL active;
@property (nonatomic, weak) id <WPSearchControllerDelegate> delegate;
@property (nonatomic, assign) BOOL dimsBackgroundDuringPresentation;         // default is YES
@property (nonatomic, assign) BOOL hidesNavigationBarDuringPresentation;     // default is YES
@property (nonatomic, strong, readonly) UIViewController *searchResultsController;
@property (nonatomic, strong, readonly) UISearchBar *searchBar;

- (instancetype)initWithSearchResultsController:(UIViewController *)searchResultsController;

@end
