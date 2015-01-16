#import "UIView+Subviews.h"

@implementation UIView (Subviews)

- (void)addSubviewWithFadeAnimation:(UIView *)subview
{
    [self addSubview:subview];
    [subview fadeInWithAnimation];
}

- (void)fadeInWithAnimation
{
    CGFloat finalAlpha = self.alpha;
    
    self.alpha = 0.0;
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = finalAlpha;
    }];
}

@end
