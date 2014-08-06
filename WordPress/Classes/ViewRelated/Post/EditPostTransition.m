#import "EditPostTransition.h"

const CGFloat EDITPOST_ANIMATION_PRESENT_DURATION = .33f;
const CGFloat EDITPOST_ANIMATION_DISMISS_DURATION = .25f;

@implementation EditPostTransition

#pragma mark - UIViewControllerAnimatedTransitioning 

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return (self.mode == EditPostTransitionModePresent) ? EDITPOST_ANIMATION_PRESENT_DURATION : EDITPOST_ANIMATION_DISMISS_DURATION;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    if (self.mode == EditPostTransitionModePresent) {
        toVC.view.alpha = 0.0;
        UIView *container = [transitionContext containerView];
        [container addSubview:toVC.view];
        
        [UIView transitionWithView:toVC.view
                          duration:EDITPOST_ANIMATION_PRESENT_DURATION
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            fromVC.view.alpha = 0.0;
                            toVC.view.alpha = 1.0;
                        }
                        completion:^(BOOL finished){
                            fromVC.view.alpha = 0.0;
                            toVC.view.alpha = 1.0;
                            [transitionContext completeTransition:YES];
                        }];

    } else {
        UIView *container = [transitionContext containerView];
        [container addSubview:toVC.view];
        
        [UIView transitionWithView:toVC.view
                          duration:EDITPOST_ANIMATION_DISMISS_DURATION
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            fromVC.view.alpha = 0.0;
                            toVC.view.alpha = 1.0;
                        }
                        completion:^(BOOL finished){
                            [fromVC.view removeFromSuperview];
                            [transitionContext completeTransition:YES];
                        }];
    }
}

@end
