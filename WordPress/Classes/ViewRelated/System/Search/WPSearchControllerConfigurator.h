#import <Foundation/Foundation.h>
#import "WPSearchController.h"

extern const CGFloat SearchBarWidth;
extern const CGFloat SearchBariPadWidth;
extern const CGFloat SearchWrapperViewPortraitHeight;
extern const CGFloat SearchWrapperViewLandscapeHeight;

@interface WPSearchControllerConfigurator : NSObject

- (instancetype)initWithSearchController:(WPSearchController *)searchController
                   withSearchWrapperView:(UIView *)searchWrapperView
                            withDelegate:(id<WPSearchControllerDelegate, WPSearchResultsUpdating>)delegate;
- (void)configureSearchControllerBarAndWrapperView;
@end
