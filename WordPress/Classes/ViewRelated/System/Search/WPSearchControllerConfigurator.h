#import <Foundation/Foundation.h>
#import "WPSearchController.h"

extern const CGFloat SearchBarWidth;
extern const CGFloat SearchBariPadWidth;
extern const CGFloat SearchWrapperViewPortraitHeight;
extern const CGFloat SearchWrapperViewLandscapeHeight;
extern const NSTimeInterval SearchBarAnimationDuration;

@interface WPSearchControllerConfigurator : NSObject

- (instancetype)init __attribute__((unavailable("Must call initWithSearchController")));
- (instancetype)initWithSearchController:(WPSearchController *)searchController
                   withSearchWrapperView:(UIView *)searchWrapperView;
- (void)configureSearchControllerBarAndWrapperView;

@end
