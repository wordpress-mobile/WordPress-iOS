#import "WPBackgroundDimmerView.h"
#import "WPGUIConstants.h"

typedef void(^AnimatableTransitionBlock)();

const CGFloat WPBackgroundDimmerViewAlphaVisible = 0.8f;

@implementation WPBackgroundDimmerView

#pragma mark - UIView

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    if (newSuperview) {
        NSAssert([newSuperview isKindOfClass:[UIView class]],
                 @"We're expecting the superview to be an object of class UIView.");
        
        self.frame = newSuperview.bounds;
        self.backgroundColor = [UIColor clearColor];
    }
}

#pragma mark - Showing and hiding

- (void)hideAnimated:(BOOL)animated
          completion:(WPBackgroundDimmerCompletionBlock)completion
{
    AnimatableTransitionBlock hideTransitionBlock = ^void() {
        self.backgroundColor = [UIColor clearColor];
    };
    
    [self transitionWithBlock:hideTransitionBlock
                     duration:WPAnimationDurationFast
                   completion:completion
                     animated:animated];
}

- (void)showAnimated:(BOOL)animated
          completion:(WPBackgroundDimmerCompletionBlock)completion
{
    AnimatableTransitionBlock showTransitionBlock = ^void() {
        self.backgroundColor = [UIColor colorWithWhite:WPColorZero
                                                 alpha:WPBackgroundDimmerViewAlphaVisible];
    };
    
    [self transitionWithBlock:showTransitionBlock
                     duration:WPAnimationDurationFast
                   completion:completion
                     animated:animated];
}

#pragma mark - Animated transitions

/**
 *  @brief      Transitions GUI elements, with or without animation.
 *  @details    This basically wraps the pattern we're using in this class to support visual
 *              transitions that can be both animated or instantaneous.
 *
 *  @param      transitionBlock     The transition to perform.  It's up to the caller to make sure
 *                                  all changes performed in this block can be animated.
 *  @param      duration            The animation duration.
 *  @param      completion          The block to execute when the transition completes.  Can be nil.
 *  @param      animated            YES means the transition will be animated (as long as the
 *                                  transition block makes changes that support animations.
 *                                  NO means the transition will be instantaneous.
 */
- (void)transitionWithBlock:(AnimatableTransitionBlock)transitionBlock
                   duration:(CGFloat)duration
                 completion:(WPBackgroundDimmerCompletionBlock)completion
                   animated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:duration
                         animations:transitionBlock
                         completion:completion];
    } else {
        transitionBlock();
        
        if (completion) {
            completion(YES);
        }
    }
}

@end
