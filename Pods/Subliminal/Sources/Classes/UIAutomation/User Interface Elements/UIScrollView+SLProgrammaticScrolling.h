//
//  UIScrollView+SLProgrammaticScrolling.h
//  Subliminal
//
//  Created by Jeffrey Wear on 9/19/13.
//  Copyright (c) 2013 Inkling. All rights reserved.
//

#import <UIKit/UIKit.h>

#if TARGET_IPHONE_SIMULATOR

/**
 The methods in the `UIScrollView(SLProgrammaticScrolling)` category allow Subliminal 
 to programmatically scroll a `UIScrollView`. Subliminal requires this ability because, 
 in the iOS 7 Simulator, scroll views' pan gesture recognizers fail to respond to UIAutomation drag gestures.
 
 NOTE: The implementation of this category uses a private API. _However_, this poses no risk 
 of discovery by Apple's review team (to projects linking Subliminal) because this category
 is only compiled for the Simulator.
 */
@interface UIScrollView (SLProgrammaticScrolling)

/**
 Scrolls the receiver by applying a relative content offset.
 
 This method is to be used, instead of `-setContentOffset:animated:`, 
 because it notifies the receiver's delegate of scroll events as if a user was dragging the receiver.
 
 Each offset specified as argument to this method describes a pair of _x_ and _y_ values, 
 each ranging from `0.0` to `1.0`. These values represent, respectively, relative horizontal 
 and vertical positions within the receiver's `-accessibilityFrame`, with `{0.0, 0.0}` 
 as the top left and `{1.0, 1.0}` as the bottom right.
 
 This method will scroll with animation, but the duration of that animation 
 is not known or subject to Subliminal's control.

 @warning This method uses an API which is only available as of iOS 7 and so must not be called
 when running on iOS 6.1 or below. (It cannot be conditionally compiled for the iOS 7 SDK
 because it is required by applications built using older SDKs but running on iOS 7).
 
 @warning This method does not deliver touch events to the receiver,
 thus UIAutomation's `UIAElement.dragInsideWithOptions` should be used concurrently.

 @warning This method disables the receiver's `panGestureRecognizer`. (This method should be only used
 in circumstances where that recognizer is non-functional anyway.)
 
 @param startOffset The offset, within the element's accessibility frame, at which to begin dragging.
 @param endOffset   The offset, within the element's accessibility frame, at which to end dragging.
 
 @exception NSInternalInconsistencyException if this method is called when running on iOS 6.1 or below.
 */
- (void)slScrollWithStartOffset:(CGPoint)startOffset endOffset:(CGPoint)endOffset;

@end

#endif
