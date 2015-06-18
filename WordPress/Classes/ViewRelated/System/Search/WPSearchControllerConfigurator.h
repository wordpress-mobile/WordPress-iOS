#import <Foundation/Foundation.h>
#import "WPSearchController.h"

/**
 WPSeachControllerConfigurator is a worker class that does the work of
 configuring the SearchController and SearchBar properties that multiple
 view controllers have. Once WPSearchController is deprecated (iOS 7 support)
 is removed, searchController must be an instance of UISearchController
 */

extern const CGFloat SearchBarWidth;
extern const CGFloat SearchBariPadWidth;
extern const CGFloat SearchWrapperViewPortraitHeight;
extern const CGFloat SearchWrapperViewLandscapeHeight;
extern const NSTimeInterval SearchBarAnimationDuration;

@interface WPSearchControllerConfigurator : NSObject

- (instancetype)init __attribute__((unavailable("Must call initWithSearchController")));
- (instancetype)initWithSearchController:(WPSearchController *)searchController
                   withSearchWrapperView:(UIView *)searchWrapperView;

// Sets properties of the searchController, searchBar, and searchWrapperView
- (void)configureSearchControllerBarAndWrapperView;

@end
