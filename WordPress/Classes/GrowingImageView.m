//
//  GrowingImageView.m
//  WordPress
//
//  Created by Brennan Stehling on 8/14/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "GrowingImageView.h"

#pragma mark -
#pragma mark Class Extension

@interface GrowingImageView ()

@property (weak, nonatomic) UIImageView *fullImageView;

@end

@implementation GrowingImageView

#pragma mark -
#pragma mark Lifecycle Methods

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        // attach tap gesture
        UITapGestureRecognizer *growingTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(originalImageViewTapped:)];
        self.gestureRecognizers = @[growingTapGestureRecognizer];
        self.userInteractionEnabled = TRUE;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // ensure the required outlet is set (should view of the top view controller to fill full screen)
    NSAssert1(self.fullView, @"Outlet is required", nil);
}

#pragma mark -
#pragma mark Instance Methods

- (IBAction)originalImageViewTapped:(id)sender {
    [self growFullImageView:TRUE];
}

- (IBAction)fullImageViewTapped:(id)sender {
    [self shrinkFullImageView:TRUE];
}

- (CGRect)originalFrame {
    CGPoint point = [self.fullView convertPoint:self.bounds.origin fromView:self];
    CGFloat width = CGRectGetWidth(self.frame);
    CGFloat height = CGRectGetHeight(self.frame);
    
    if ([[UIApplication sharedApplication] isStatusBarHidden]) {
        return CGRectMake(point.x, point.y, width, height);
    }
    else {
        if (!UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])) {
            return CGRectMake(point.x, point.y, width, height);
        }
        else {
            return CGRectMake(point.x, point.y, width, height);
        }
    }
}

- (CGRect)fullFrame {
    CGFloat width = CGRectGetWidth(self.fullView.frame);
    CGFloat height = CGRectGetHeight(self.fullView.frame);
    
    return CGRectMake(0, 0, width, height);
}

- (void)growFullImageView:(BOOL)animated {
    CGRect originalFrame = [self originalFrame];
    
    UIImageView *fullImageView = [[UIImageView alloc] initWithFrame:originalFrame];
    fullImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    fullImageView.contentMode = UIViewContentModeScaleAspectFit;
    fullImageView.backgroundColor = [UIColor clearColor];
    fullImageView.image = self.image;
    fullImageView.userInteractionEnabled = TRUE;
    
    UITapGestureRecognizer *fullImageViewTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fullImageViewTapped:)];
    fullImageView.gestureRecognizers = @[fullImageViewTapGestureRecognizer];
    
    [self.fullView addSubview:fullImageView];
    
    CGFloat duration = animated ? 0.25 : 0.0;
    
    CGRect fullFrame = [self fullFrame];
    [UIView animateWithDuration:duration animations:^{
        fullImageView.frame = fullFrame;
        fullImageView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.9];
    } completion:^(BOOL finished) {
        // do nothing
    }];
    
    self.fullImageView = fullImageView;
}

- (void)shrinkFullImageView:(BOOL)animated {
    if (!self.fullImageView) {
        return;
    }
    
    if (!animated) {
        [self.fullImageView removeFromSuperview];
        self.fullImageView = nil; // just a redundant step to free this property
    }
    
    CGRect originalFrame = [self originalFrame];
    
    self.fullImageView.backgroundColor = [UIColor clearColor];
    
    [UIView animateWithDuration:0.25 animations:^{
        self.fullImageView.frame = originalFrame;
    } completion:^(BOOL finished) {
        [self.fullImageView removeFromSuperview];
        self.fullImageView = nil; // just a redundant step to free this property
    }];
}

@end
