@import UIKit;

@interface WPAnimatedBox : UIView

/// Animates the view.  If the animation is already running, does nothing.
///
- (void)animate;

/// Animates the view.  If the animation is already running, does nothing.
///
/// @param  delayInSeconds      The seconds, or fraction of a second, to wait before animating
///                             the view.
///
- (void)animateAfterDelay:(NSTimeInterval)delayInSeconds;

/**
 Advises the box to stop animating once the current loop is complete.
 */
- (void)suspendAnimation;

@end
