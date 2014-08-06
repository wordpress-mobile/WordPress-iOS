#import "EditPostTransition.h"

const CGFloat EDITPOST_ANIMATION_PRESENT_DURATION = .33f;
const CGFloat EDITPOST_ANIMATION_DISMISS_DURATION = .33f;

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
        toVC.view.frame = [self rectForPresentedState:transitionContext];
        UIView *container = [transitionContext containerView];
        [container addSubview:toVC.view];
        
        // Now animate
        [UIView transitionWithView:toVC.view
                          duration:EDITPOST_ANIMATION_PRESENT_DURATION
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            toVC.view.alpha = 1.0;
                        }
                        completion:^(BOOL finished){
                            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
                            [fromVC.navigationController setNavigationBarHidden:YES animated:YES];
                            [fromVC.navigationController setToolbarHidden:YES animated:YES];
                            toVC.view.frame = [self rectForPresentedState:transitionContext];
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
                            toVC.view.alpha = 1.0;
                        }
                        completion:^(BOOL finished){
                            toVC.view.alpha = 1.0;
                            fromVC.view.alpha = 0.0;
                            fromVC.view.frame = [self rectForDismissedState:transitionContext];
                            [fromVC.view removeFromSuperview];
                            [transitionContext completeTransition:YES];
                        }];
    }
}

# pragma mark - Helpers

- (CGRect)rectForDismissedState:(id<UIViewControllerContextTransitioning>)transitionContext
{
    CGFloat currentHeight = [self currentSize].height;
    
    UIViewController *fromViewController;
    UIView *containerView = [transitionContext containerView];
    
    if (self.mode == EditPostTransitionModePresent)
        fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    else
        fromViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    switch (fromViewController.interfaceOrientation)
    {
        case UIInterfaceOrientationLandscapeRight:
            return CGRectMake(-currentHeight, 0,
                              currentHeight, containerView.bounds.size.height);
        case UIInterfaceOrientationLandscapeLeft:
            return CGRectMake(containerView.bounds.size.width, 0,
                              currentHeight, containerView.bounds.size.height);
        case UIInterfaceOrientationPortraitUpsideDown:
            return CGRectMake(0, -currentHeight,
                              containerView.bounds.size.width, currentHeight);
        case UIInterfaceOrientationPortrait:
            return CGRectMake(0, containerView.bounds.size.height,
                              containerView.bounds.size.width, currentHeight);
        default:
            return CGRectZero;
    }
}

- (CGRect)rectForPresentedState:(id<UIViewControllerContextTransitioning>)transitionContext
{
    CGFloat currentHeight = [self currentSize].height;
    
    UIViewController *fromViewController;
    if (self.mode == EditPostTransitionModePresent)
        fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    else
        fromViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    switch (fromViewController.interfaceOrientation)
    {
        case UIInterfaceOrientationLandscapeRight:
            return CGRectOffset([self rectForDismissedState:transitionContext], currentHeight, 0);
        case UIInterfaceOrientationLandscapeLeft:
            return CGRectOffset([self rectForDismissedState:transitionContext], -currentHeight, 0);
        case UIInterfaceOrientationPortraitUpsideDown:
            return CGRectOffset([self rectForDismissedState:transitionContext], 0, currentHeight);
        case UIInterfaceOrientationPortrait:
            return CGRectOffset([self rectForDismissedState:transitionContext], 0, -currentHeight);
        default:
            return CGRectZero;
    }
}

- (CGSize)currentSize
{
    return [self sizeInOrientation:[UIApplication sharedApplication].statusBarOrientation];
}

- (CGSize)sizeInOrientation:(UIInterfaceOrientation)orientation
{
    CGSize size = [UIScreen mainScreen].bounds.size;
    UIApplication *application = [UIApplication sharedApplication];
    if (UIInterfaceOrientationIsLandscape(orientation))
    {
        size = CGSizeMake(size.height, size.width);
    }
    if (application.statusBarHidden == NO)
    {
        size.height -= MIN(application.statusBarFrame.size.width, application.statusBarFrame.size.height);
    }
    return size;
}

@end
