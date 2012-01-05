//
//  PSContainerView.h
//  PSStackedView
//
//  Created by Peter Steinberger on 7/17/11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

enum {
    PSSVSideNone = 0x0,
    PSSVSideRight = 0x01,
    PSSVSideLeft = 0x02
}typedef PSSVSide;


@interface PSSVContainerView : UIView {
    UIView *transparentView_;
    CGFloat originalWidth_;
    PSSVSide shadow_;
    UIViewController *controller_;
    CAGradientLayer *leftShadowLayer_;
    CAGradientLayer *innerShadowLayer_;
	CAGradientLayer *rightShadowLayer_;
}

+ (PSSVContainerView *)containerViewWithController:(UIViewController *)controller;

/// limit to max width
- (CGFloat)limitToMaxWidth:(CGFloat)maxWidth;

/// add rounded masks. 
/// currently unused, because this needs offscreen-rendering, which is crazy slow
/// as a workaround, fake te rounded corners yourself
- (void)addMaskToCorners:(UIRectCorner)corners;
- (void)removeMask;

/// update shadow
- (void)updateContainer;

/// set shadow sides
@property(nonatomic, assign) PSSVSide shadow;

/// view controller that is being incapsulated
@property(nonatomic, strong) UIViewController *controller;

/// darken down the view if it's not fully visible
@property(nonatomic, assign) CGFloat darkRatio;

@end
