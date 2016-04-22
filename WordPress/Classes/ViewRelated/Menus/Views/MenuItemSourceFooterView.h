#import <UIKit/UIKit.h>

@interface MenuItemSourceFooterView : UIView

/**
 The animating state of the loadingIndicator.
 */
@property (nonatomic, assign) BOOL isAnimating;

/**
 Add a message with text within the view.
 */
- (void)toggleMessageWithText:(NSString *)text;

/**
 Show the animated loading indicator.
 */
- (void)startLoadingIndicatorAnimation;

/**
 Stop the animated loading indicator.
 */
- (void)stopLoadingIndicatorAnimation;

@end
