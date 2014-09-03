//
//  UIScrollView+SLProgrammaticScrolling.m
//  Subliminal
//
//  Created by Jeffrey Wear on 9/19/13.
//  Copyright (c) 2013 Inkling. All rights reserved.
//

#import "UIScrollView+SLProgrammaticScrolling.h"

#if TARGET_IPHONE_SIMULATOR

/*
 Unlike `-[UIScrollView setContentOffset]`, 
 `-[UIScrollViewAccessibility(SafeCategory) accessibilityApplyScrollContent:sendScrollStatus:animated:]`
 (loaded onto `UIScrollView` at runtime in iOS 7) notifies the delegate of scroll events as if the scroll view
 was actually being dragged. We need to declare the method because it's a private API, 
 but we don't need to obscure the use of this API because this is only compiled for the Simulator.
 */
@interface UIScrollView (SLProgrammaticScrolling_Internal)

- (void)accessibilityApplyScrollContent:(CGPoint)contentOffset sendScrollStatus:(BOOL)sendStatus animated:(BOOL)animated;

@end

@implementation UIScrollView (SLProgrammaticScrolling)

- (void)slScrollWithStartOffset:(CGPoint)startOffset endOffset:(CGPoint)endOffset {
    // `-[UIScrollViewAccessibility(SafeCategory) accessibilityApplyScrollContent:sendScrollStatus:animated:]`
    // is only present in iOS 7
    NSAssert(kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_6_1,
             @"%s is only supported on iOS 7.", __PRETTY_FUNCTION__);

    CGRect accessibilityFrame = self.accessibilityFrame;
    CGPoint currentContentOffset = self.contentOffset;
    CGPoint newContentOffset = {
        .x = currentContentOffset.x + ((startOffset.x - endOffset.x) * CGRectGetWidth(accessibilityFrame)),
        .y = currentContentOffset.y + ((startOffset.y - endOffset.y) * CGRectGetHeight(accessibilityFrame))
    };

    // despite not ultimately causing the scroll view to scroll, the scroll view's pan gesture recognizer
    // does appear to receive touches (i.e. those concurrently delivered by `UIAElement.dragInsideWithOptions`)
    // and the scroll view then gets as far as calling `-[UIScrollView(UIScrollViewInternal) _scrollViewWillBeginDragging]`
    // ...and then some conflict between that flow, and `-accessibilityApplyScrollContent:sendScrollStatus:animated:`
    // having been called, causes an occasional crash
    // so, since the gesture recognizer's not going to do the job anyway, we disable it
    self.panGestureRecognizer.enabled = NO;

    // I don't know what the second parameter does--either `NO` or `YES` appears to work in the Simulator
    // --but it is `NO` when scrolling with VoiceOver on in an iOS device;
    // we pass animated:`YES` because a user would drag with some duration.
    [self accessibilityApplyScrollContent:newContentOffset sendScrollStatus:NO animated:YES];
}

@end

#endif
