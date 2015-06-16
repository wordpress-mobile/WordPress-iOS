#import <Foundation/Foundation.h>
#import "WPSearchController.h"

extern const CGFloat SearchBarWidth;
extern const CGFloat SearchBariPadWidth;
extern const CGFloat SearchWrapperViewPortraitHeight;
extern const CGFloat SearchWrapperViewLandscapeHeight;
extern const NSTimeInterval SearchBarAnimationDuration;

@protocol WPSearchControllerWithResultsUpdatingDelegate <NSObject>

@required
- (void)presentSearchController:(WPSearchController *)searchController;
- (void)willPresentSearchController:(WPSearchController *)searchController;
- (void)willDismissSearchController:(WPSearchController *)searchController;
- (void)updateSearchResultsForSearchController:(WPSearchController *)searchController;

@end

@interface WPSearchControllerConfigurator : NSObject

- (instancetype)init __attribute__((unavailable("Must call initWithSearchController")));
- (instancetype)initWithSearchController:(WPSearchController *)searchController
                   withSearchWrapperView:(UIView *)searchWrapperView
                            withDelegate:(id<WPSearchControllerWithResultsUpdatingDelegate>)delegate;
- (void)configureSearchControllerBarAndWrapperView;

@end
