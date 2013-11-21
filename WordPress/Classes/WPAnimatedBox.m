//
//  WPAnimatedBox.m
//  WordPress
//
//  Created by Tom Witkin on 11/20/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPAnimatedBox.h"

@interface WPAnimatedBox () {
    
    UIImageView *container;
    UIImageView *page1;
    UIImageView *page2;
    UIImageView *page3;
    BOOL isPreparedToAnimate;
}

@end

@implementation WPAnimatedBox

static CGFloat const WPAnimatedBoxSideLength = 86.0;
static CGFloat const WPAnimatedBoxAnimationTolerance = 5.0;

+ (id)new {
    WPAnimatedBox *animatedBox = [[WPAnimatedBox alloc] init];
    [animatedBox setupView];
    return animatedBox;
}

- (void)setupView {
    
    container = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"animatedBox"]];
    [container sizeToFit];
    
    page1 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"animatedBoxPage1"]];
    [page1 sizeToFit];
    
    page2 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"animatedBoxPage2"]];
    [page2 sizeToFit];
    
    page3 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"animatedBoxPage3"]];
    [page3 sizeToFit];
    
    // view's are laid out by pixels for accuracy
    self.frame = CGRectMake(0, 0, WPAnimatedBoxSideLength, WPAnimatedBoxSideLength);
    container.frame = CGRectMake(0, CGRectGetHeight(self.frame) - CGRectGetHeight(container.frame), CGRectGetWidth(container.frame), CGRectGetHeight(container.frame));
    page1.frame = CGRectMake(28, WPAnimatedBoxAnimationTolerance + 11, CGRectGetWidth(page1.frame), CGRectGetHeight(page1.frame));
    page2.frame = CGRectMake(17, WPAnimatedBoxAnimationTolerance + 0, CGRectGetWidth(page2.frame), CGRectGetHeight(page2.frame));
    page3.frame = CGRectMake(2, WPAnimatedBoxAnimationTolerance + 15, CGRectGetWidth(page3.frame), CGRectGetHeight(page3.frame));
    
    [self addSubview:container];
    [self insertSubview:page1 belowSubview:container];
    [self insertSubview:page2 belowSubview:page1];
    [self insertSubview:page3 belowSubview:page2];
    
    // add motion effects
    UIInterpolatingMotionEffect *page1MotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"frame.origin.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    page1MotionEffect.minimumRelativeValue = [NSNumber numberWithInt:4];
    page1MotionEffect.maximumRelativeValue = [NSNumber numberWithInt:-4];
    [page1 addMotionEffect:page1MotionEffect];
    
    UIInterpolatingMotionEffect *page3MotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"frame.origin.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    page3MotionEffect.minimumRelativeValue = [NSNumber numberWithInt:7];
    page3MotionEffect.maximumRelativeValue = [NSNumber numberWithInt:-7];
    [page3 addMotionEffect:page3MotionEffect];
    
    self.clipsToBounds = YES;
}

- (void)prepareAnimation:(BOOL)animated {
    
    if (isPreparedToAnimate) {
        return;
    }
    
    [UIView animateWithDuration:animated ? 0.2 : 0.0
                     animations:^{
                         // Transform pages all the way down
                         NSArray *pages = @[page1, page2, page3];
                         for (UIView *view in pages) {
                             CGFloat YOrigin = CGRectGetMinY(view.frame);
                             view.transform = CGAffineTransformMakeTranslation(0, CGRectGetHeight(self.frame) - YOrigin);
                         }
                     }];
    
    isPreparedToAnimate = YES;
}

- (void)animate {
    
    isPreparedToAnimate = NO;
    
    [UIView animateWithDuration:1.4 delay:0.1 usingSpringWithDamping:0.5 initialSpringVelocity:0.1 options:UIViewAnimationOptionCurveEaseOut animations:^{
        page1.transform = CGAffineTransformIdentity;
    } completion:nil];
    [UIView animateWithDuration:1 delay:0.0 usingSpringWithDamping:0.65 initialSpringVelocity:0.01 options:UIViewAnimationOptionCurveEaseOut animations:^{
        page2.transform = CGAffineTransformIdentity;
    } completion:nil];
    [UIView animateWithDuration:1.2 delay:0.2 usingSpringWithDamping:0.5 initialSpringVelocity:0.1 options:UIViewAnimationOptionCurveEaseOut animations:^{
        page3.transform = CGAffineTransformIdentity;
    } completion:nil];
}

@end
