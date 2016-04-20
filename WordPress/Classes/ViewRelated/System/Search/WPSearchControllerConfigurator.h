#import <Foundation/Foundation.h>
#import "WPSearchController.h"

extern const CGFloat SearchBarWidth;
extern const CGFloat SearchBariPadWidth;
extern const CGFloat SearchWrapperViewMinHeight;
extern const NSTimeInterval SearchBarAnimationDuration;

/**
 * @class WPSearchControllerConfigurator
 * @brief Worker class that configures the SearchController and SearchBar properties that multiple
 * view controllers have.
 * @details Once WPSearchController is deprecated (iOS 7 support) is removed, searchController
 * must be an instance of UISearchController
 */

@interface WPSearchControllerConfigurator : NSObject

/**
 * @brief unavailable init method
 */
- (instancetype)init __attribute__((unavailable("Must call initWithSearchController")));

/**
 * @brief Initializes class with searchController and searchWrapperView that needs configuration
 *
 * @param searchController  the searchController to configure
 * @param searchWrapperView the UIView that contains the searchController
 */
- (instancetype)initWithSearchController:(WPSearchController *)searchController
                   withSearchWrapperView:(UIView *)searchWrapperView;

/**
 * @brief Sets properties of the searchController, searchBar, and searchWrapperView
 */
- (void)configureSearchControllerAndWrapperView;

@end
