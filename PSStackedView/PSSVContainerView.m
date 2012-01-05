//
//  PSContainerView.m
//  PSStackedView
//
//  Created by Peter Steinberger on 7/17/11.
//  Copyright 2011 Peter Steinberger. All rights reserved.
//

#import "PSSVContainerView.h"
#import "PSStackedViewGlobal.h"
#import "UIView+PSSizes.h"

#define kPSSVCornerRadius 6.f
#define kPSSVShadowWidth 60.f
#define kPSSVShadowAlpha 0.5f

@interface PSSVContainerView ()
@property(nonatomic, assign) CGFloat originalWidth;
@property(nonatomic, strong) CAGradientLayer *leftShadowLayer;
@property(nonatomic, strong) CAGradientLayer *innerShadowLayer;
@property(nonatomic, strong) CAGradientLayer *rightShadowLayer;
@property(nonatomic, strong) UIView *transparentView;
@end

@implementation PSSVContainerView

@synthesize shadow = shadow_;
@synthesize originalWidth = originalWidth_;
@synthesize controller = controller_;
@synthesize leftShadowLayer = leftShadowLayer_;
@synthesize innerShadowLayer = innerShadowLayer_;
@synthesize rightShadowLayer = rightShadowLayer_;
@synthesize transparentView = transparentView_;

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark private

// creates vertical shadow
- (CAGradientLayer *)shadowAsInverse:(BOOL)inverse {
	CAGradientLayer *newShadow = [[CAGradientLayer alloc] init];
    newShadow.startPoint = CGPointMake(0, 0.5);
    newShadow.endPoint = CGPointMake(1.0, 0.5);
	CGColorRef darkColor  = (CGColorRef)CFRetain([UIColor colorWithWhite:0.0f alpha:kPSSVShadowAlpha].CGColor);
	CGColorRef lightColor = (CGColorRef)CFRetain([UIColor clearColor].CGColor);
	newShadow.colors = [NSArray arrayWithObjects:
                        (__bridge id)(inverse ? lightColor : darkColor),
                        (__bridge id)(inverse ? darkColor : lightColor),
                        nil];
    
    CFRelease(darkColor);
    CFRelease(lightColor);
	return newShadow;
}

// return available shadows as set, for easy enumeration
- (NSSet *)shadowSet {
    NSMutableSet *set = [NSMutableSet set];
    if (self.leftShadowLayer) {
        [set addObject:self.leftShadowLayer];
    }
    if (self.innerShadowLayer) {
        [set addObject:self.innerShadowLayer];
    }
    if (self.rightShadowLayer) {
        [set addObject:self.rightShadowLayer];
    }
    return [set copy];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSObject

+ (PSSVContainerView *)containerViewWithController:(UIViewController *)controller; {
    PSSVContainerView *view = [[PSSVContainerView alloc] initWithFrame:controller.view.frame];
    view.controller = controller;    
    return view;
}

- (void)dealloc {
    [self removeMask];
    self.shadow = PSSVSideNone; // TODO needed?
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIView

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];

    // adapt layer heights
    for (CALayer *layer in [self shadowSet]) {
        CGRect aFrame = layer.frame;
        aFrame.size.height = frame.size.height;
        layer.frame = aFrame;
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public

- (CGFloat)limitToMaxWidth:(CGFloat)maxWidth; {
    BOOL widthChanged = NO;
    
    if (maxWidth && self.width > maxWidth) {
        self.width = maxWidth;
        widthChanged = YES;
    }else if(self.originalWidth && self.width < self.originalWidth) {
        self.width = MIN(maxWidth, self.originalWidth);
        widthChanged = YES;
    }
    self.controller.view.width = self.width;
    
    // update shadow layers for new width
    if (widthChanged) {
        [self updateContainer];
    }
    
    return self.width;
}

- (void)setController:(UIViewController *)aController {
    if (controller_ != aController) {
        if (controller_) {
            [controller_.view removeFromSuperview];
        }        
        controller_ = aController;
        
        // properly embed view
        self.originalWidth = self.controller.view.width;
        controller_.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth; 
        controller_.view.frame = CGRectMake(0, 0, controller_.view.width, controller_.view.height);
        [self addSubview:controller_.view];
        [self bringSubviewToFront:transparentView_];
    }
}

- (void)addMaskToCorners:(UIRectCorner)corners; {
    // Re-calculate the size of the mask to account for adding/removing rows.
    CGRect frame = self.controller.view.bounds;
    if([self.controller.view isKindOfClass:[UIScrollView class]] && ((UIScrollView *)self.controller.view).contentSize.height > self.controller.view.frame.size.height) {
    	frame.size = ((UIScrollView *)self.controller.view).contentSize;
    } else {
        frame.size = self.controller.view.frame.size;
    }
    
    // Create the path (with only the top-left corner rounded)
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:frame 
                                                   byRoundingCorners:corners
                                                         cornerRadii:CGSizeMake(kPSSVCornerRadius, kPSSVCornerRadius)];
    
    // Create the shape layer and set its path
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = frame;
    maskLayer.path = maskPath.CGPath;
    
    // Set the newly created shape layer as the mask for the image view's layer
    self.controller.view.layer.mask = maskLayer;
}

- (void)removeMask; {
    self.controller.view.layer.mask = nil;
}

- (void)updateContainer {
    // re-set shadow property
    self.shadow = shadow_;
}

- (void)setShadow:(PSSVSide)shadow {
    shadow_ = shadow;
    
    if (shadow & PSSVSideLeft) {
        if (!self.leftShadowLayer) {
            CAGradientLayer *leftShadow = [self shadowAsInverse:YES];
            self.leftShadowLayer = leftShadow;
        }
        self.leftShadowLayer.frame = CGRectMake(-kPSSVShadowWidth, 0, kPSSVShadowWidth+kPSSVCornerRadius, self.controller.view.height);;
        if ([self.layer.sublayers indexOfObjectIdenticalTo:self.leftShadowLayer] != 0) {
            [self.layer insertSublayer:self.leftShadowLayer atIndex:0];
        }
    }else {
        [self.leftShadowLayer removeFromSuperlayer];
    }
    
    if (shadow & PSSVSideRight) {
        if (!self.rightShadowLayer) {
            CAGradientLayer *rightShadow = [self shadowAsInverse:NO];
            self.rightShadowLayer = rightShadow;
        }
        self.rightShadowLayer.frame = CGRectMake(self.width-kPSSVCornerRadius, 0, kPSSVShadowWidth, self.controller.view.height);
        if ([self.layer.sublayers indexOfObjectIdenticalTo:self.rightShadowLayer] != 0) {
            [self.layer insertSublayer:self.rightShadowLayer atIndex:0];
        }
    }else {
        [self.rightShadowLayer removeFromSuperlayer];
    }
    
    if (shadow) {
        if (!self.innerShadowLayer) {
            CAGradientLayer *innerShadow = [[CAGradientLayer alloc] init];
            innerShadow.colors = [NSArray arrayWithObjects:(id)[UIColor colorWithWhite:0.0f alpha:kPSSVShadowAlpha].CGColor, (id)[UIColor colorWithWhite:0.0f alpha:kPSSVShadowAlpha].CGColor, nil];
            self.innerShadowLayer = innerShadow;
        }
        self.innerShadowLayer.frame = CGRectMake(kPSSVCornerRadius, 0, self.width-kPSSVCornerRadius*2, self.controller.view.height);
        if ([self.layer.sublayers indexOfObjectIdenticalTo:self.innerShadowLayer] != 0) {
            [self.layer insertSublayer:self.innerShadowLayer atIndex:0];
        }
    }else {
        [self.innerShadowLayer removeFromSuperlayer];
    }
}

- (void)setDarkRatio:(CGFloat)darkRatio {
    BOOL isTransparent = darkRatio > 0.01f;
    
    if (isTransparent && !transparentView_) {
        transparentView_ = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, self.width, self.height)];
        transparentView_.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        transparentView_.backgroundColor = [UIColor blackColor];
        transparentView_.alpha = 0.f;
        transparentView_.userInteractionEnabled = NO;
        [self addSubview:transparentView_];
    }
    
    transparentView_.alpha = darkRatio;
}

- (CGFloat)darkRatio {
    return transparentView_.alpha;
}

@end
