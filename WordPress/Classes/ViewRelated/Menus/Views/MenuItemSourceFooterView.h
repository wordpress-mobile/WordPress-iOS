#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MenuItemSourceFooterView : UIView

/**
 The animating state of the loadingIndicator.
 */
@property (nonatomic, assign) BOOL isAnimating;

/**
 Add a message with text within the view.
 */
- (void)toggleMessageWithText:(nullable NSString *)text;

/**
 Show the animated loading indicator.
 */
- (void)startLoadingIndicatorAnimation;

/**
 Stop the animated loading indicator.
 */
- (void)stopLoadingIndicatorAnimation;

@end

NS_ASSUME_NONNULL_END
