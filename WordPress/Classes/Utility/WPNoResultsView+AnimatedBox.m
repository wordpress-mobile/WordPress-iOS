#import "WPNoResultsView+AnimatedBox.h"
#import "WPAnimatedBox.h"


@implementation WPNoResultsView (AnimatedBox)

+ (void)displayAnimatedBoxWithTitle:(NSString *)title message:(NSString *)message view:(UIView *)view;
{
    // Make sure there's no more than one instance
    [[self class] removeFromView:view];
    
    // Prepare the new instance
    WPNoResultsView *noResultsView  = [WPNoResultsView new];
    noResultsView.titleText         = title;
    noResultsView.messageText       = message;
    
    WPAnimatedBox *animatedBox      = [WPAnimatedBox newAnimatedBox];
    noResultsView.accessoryView     = animatedBox;

    [view addSubview:noResultsView];
    
    [animatedBox prepareAnimation:NO];
    [animatedBox animate];
}

+ (void)removeFromView:(UIView *)view
{
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:[self class]]) {
            [subview removeFromSuperview];
        }
    }
}

@end
