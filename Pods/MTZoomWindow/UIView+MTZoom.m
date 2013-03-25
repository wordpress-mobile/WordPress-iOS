//
//  UIView+MTZoom.m
//  MTZoomWindow
//
//  Created by Tretter Matthias on 23.10.11.
//  Copyright (c) 2011 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import "UIView+MTZoom.h"
#import "MTZoomWindow.h"
#import <objc/runtime.h>


#define kMTDefaultZoomedAutoresizingMask    UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight


static char wrapKey;
static char sizeKey;
static char autoresizingKey;
static char placeholderKey;
static char delegateKey;


@implementation UIView (MTZoom)

////////////////////////////////////////////////////////////////////////
#pragma mark - Zooming
////////////////////////////////////////////////////////////////////////

- (void)zoomIn {
    MTZoomWindow *zoomWindow = [MTZoomWindow sharedWindow];
    
    if (!zoomWindow.zoomedIn) {
        UIView *superview = self.superview;
        UIView *placeholderView = [[UIView alloc] initWithFrame:self.frame];
        
        // setup invisible copy of self
        placeholderView.autoresizingMask = self.autoresizingMask;
        [superview insertSubview:placeholderView belowSubview:self];
        self.zoomPlaceholderView = placeholderView;
        
        [self mt_callDelegateWillZoomIn];
        
        // Zoom view into fullscreen-mode and call delegate
        [zoomWindow zoomView:self toSize:self.zoomedSize];
    }
}

- (void)zoomOut {
    MTZoomWindow *zoomWindow = [MTZoomWindow sharedWindow];
    
    [self mt_callDelegateWillZoomOut];
    
    // zoom view back to original frame and call delegate
    [zoomWindow zoomOut];
}

- (void)toggleZoomState {
    if (self.zoomedIn) {
        [self zoomOut];
    } else {
        [self zoomIn];
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Properties
////////////////////////////////////////////////////////////////////////

- (void)setWrapInScrollviewWhenZoomed:(BOOL)wrapInScrollviewWhenZoomed {
    objc_setAssociatedObject(self, &wrapKey, @(wrapInScrollviewWhenZoomed), OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)isWrappedInScrollviewWhenZoomed {
    BOOL wrapSetByUser = [objc_getAssociatedObject(self, &wrapKey) boolValue];
    
    // scrollviews don't get wrapped in another scrollview
    return wrapSetByUser && ![self isKindOfClass:[UIScrollView class]] && ![self isKindOfClass:NSClassFromString(@"MKMapView")];
}

- (void)setZoomedSize:(CGSize)zoomedSize {
    objc_setAssociatedObject(self, &sizeKey, [NSValue valueWithCGSize:zoomedSize], OBJC_ASSOCIATION_RETAIN);
}

- (CGSize)zoomedSize {
    return [objc_getAssociatedObject(self, &sizeKey) CGSizeValue];
}

- (void)setZoomedAutoresizingMask:(UIViewAutoresizing)zoomedAutoresizingMask {
    objc_setAssociatedObject(self, &autoresizingKey, @(zoomedAutoresizingMask), OBJC_ASSOCIATION_RETAIN);
}

- (UIViewAutoresizing)zoomedAutoresizingMask {
    id autoresizingNumber = objc_getAssociatedObject(self, &autoresizingKey);
    
    if (autoresizingNumber == nil) {
        return kMTDefaultZoomedAutoresizingMask;
    }
    
    return (UIViewAutoresizing)[autoresizingNumber intValue];
}

- (void)setZoomDelegate:(id<MTZoomWindowDelegate>)zoomDelegate {
    objc_setAssociatedObject(self, &delegateKey, zoomDelegate, OBJC_ASSOCIATION_ASSIGN);
}

- (id<MTZoomWindowDelegate>)zoomDelegate {
    return objc_getAssociatedObject(self, &delegateKey);
}

- (BOOL)isZoomedIn {
    return [MTZoomWindow sharedWindow].zoomedIn && [MTZoomWindow sharedWindow].zoomedView == self;
}

- (void)setZoomPlaceholderView:(UIView *)zoomPlaceholderView {
    objc_setAssociatedObject(self, &placeholderKey, zoomPlaceholderView, OBJC_ASSOCIATION_RETAIN);
}

- (UIView *)zoomPlaceholderView {
    return (UIView *)objc_getAssociatedObject(self, &placeholderKey);
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private Delegate Calls
////////////////////////////////////////////////////////////////////////

- (void)mt_callDelegateWillZoomIn {
    id<MTZoomWindowDelegate> delegate = self.zoomDelegate;
    
    if ([delegate respondsToSelector:@selector(zoomWindow:willZoomInView:)]) {
        [delegate zoomWindow:[MTZoomWindow sharedWindow] willZoomInView:self];
    }
}

- (void)mt_callDelegateDidZoomIn {
    id<MTZoomWindowDelegate> delegate = self.zoomDelegate;
    
    if ([delegate respondsToSelector:@selector(zoomWindow:didZoomInView:)]) {
        [delegate zoomWindow:[MTZoomWindow sharedWindow] didZoomInView:self];
    }
}

- (void)mt_callDelegateWillZoomOut {
    id<MTZoomWindowDelegate> delegate = self.zoomDelegate;
    
    if ([delegate respondsToSelector:@selector(zoomWindow:willZoomOutView:)]) {
        [delegate zoomWindow:[MTZoomWindow sharedWindow] willZoomOutView:self];
    }
}

- (void)mt_callDelegateDidZoomOut {
    id<MTZoomWindowDelegate> delegate = self.zoomDelegate;
    
    if ([delegate respondsToSelector:@selector(zoomWindow:didZoomOutView:)]) {
        [delegate zoomWindow:[MTZoomWindow sharedWindow] didZoomOutView:self];
    }
}

@end
