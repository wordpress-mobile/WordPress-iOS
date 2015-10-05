#import <UIKit/UIKit.h>

@interface WPAnimatedBox : UIView

+ (instancetype)newAnimatedBox;
- (void)prepareAnimation:(BOOL)animated;
- (void)animate;

/**
 Immediately prepares the view to animate. The preparation does not animate.
 Plays the animation after the specified delay.

 @param delayInSeconds The seconds, or fraction of a second, to wait before animating
 the view.
 */
- (void)prepareAndAnimateAfterDelay:(CGFloat)delayInSeconds;

@end
