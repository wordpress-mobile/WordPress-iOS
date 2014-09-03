//
//  SLUIAElement.h
//  Subliminal
//
//  For details and documentation:
//  http://github.com/inkling/Subliminal
//
//  Copyright 2013-2014 Inkling Systems, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

/**
 `SLUIAElement` is an abstract class that defines an interface to
 access and manipulate a user interface element within your application.

 Concrete subclasses of `SLUIAElement`, `SLElement` and `SLStaticElement`, 
 handle the specifics of matching particular elements. 
 */
@interface SLUIAElement : NSObject

#pragma mark - Configuring the Default Timeout
/// ----------------------------------------
/// @name Configuring the Default Timeout
/// ----------------------------------------

/**
 Establishes the value of the grace period during which instances `SLUIAElement`
 wait to establish access to their corresponding interface elements.

 Clients change this value by setting the default timeout used by the shared
 test controller (-[SLTestController setDefaultTimeout:]) before testing begins.
 
 @param timeout The new value of the "grace period" that instances of `SLUIAElement` use
 to establish access to their corresponding interface elements.

 @see +defaultTimeout
 */
+ (void)setDefaultTimeout:(NSTimeInterval)timeout;

/**
 The value of the grace period during which instances of `SLUIAElement`
 wait to establish access to their corresponding interface elements.

 When asked to access their corresponding elements, instances of `SLUIAElement`
 automatically wait for those elements to become [valid](-isValid), for not more 
 than this timeout value. If that access requires simulating user interaction,
 instances of `SLUIAElement` will additionally wait, for the remainder of the 
 timeout, for their corresponding elements to become [tappable](-isTappable).

 This means that tests rarely need to wait for the user interface to update 
 before attempting to access or interact with interface elements.
 
 @return The value of the grace period that instances of `SLUIAElement` use
 to establish access to their corresponding interface elements.

 @see +setDefaultTimeout:
 @see -isValid
 @see -isTappable
 */
+ (NSTimeInterval)defaultTimeout;

#pragma mark - Determining Element State
/// ----------------------------------------
/// @name Determining Element State
/// ----------------------------------------

/**
 Determines whether a user interface element matching the specified `SLUIAElement` 
 currently exists.

 An element's state can be accessed if and only if it is valid.
 
 This method returns immediately. All other methods, unless marked otherwise,
 wait up to [default timeout](+defaultTimeout) for the element to become valid, 
 and raise an `SLUIAElementInvalidException` if the element does not become valid 
 within that interval.
 
 Use of the `UIAElement` macro can help tests diagnose validity failures.
 
 Validity is not cached, but is determined anew every time a `SLUIAElement` is
 asked to access a corresponding interface element.
 
 @return `YES` if a matching element currently exists, `NO` otherwise.
 
 @see -isTappable
 */
- (BOOL)isValid;

/**
 Determines whether the specified element is visible on the screen.

 This method returns, or raises an `SLUIAElementInvalidException`, immediately.

 @return `YES` if the user interface element represented by the specified element
 is visible on-screen, `NO` otherwise.

 @exception SLUIAElementInvalidException Raised if the element is not currently
 valid. For this reason, developers are encouraged to use `-isValidAndVisible` and
 `-isInvalidOrInvisible` with `SLAssertTrueWithTimeout`, rather than this method. 
 */
- (BOOL)isVisible;

/**
 Determines whether the specified element is valid, and if so, if it is visible 
 on the screen.

 This method returns immediately, but unlike `-isVisible`, will not raise 
 an `SLUIAElementInvalidException` if the element is not valid--it will
 just return `NO`. This allows test writers to wait for an element to appear 
 without having to worry about whether the element is valid at the start of the wait.

 @return `YES` if the user interface element represented by the specified element 
 both [exists](-isValid) and is [visible](-isVisible), `NO` otherwise.
 */
- (BOOL)isValidAndVisible;

/**
 Determines whether the specified element is invalid or, if it is valid, 
 if it is invisible.
 
 Unlike `-isVisible`, this method will not raise an `SLUIAElementInvalidException`
 if the element is not valid--it will just return `NO`. This allows test writers
 to wait for an element to disappear without having to worry about whether 
 the element will become invisible or simply invalid.
 
 @return `YES` if the user interface element represented by the specified element 
 [does not exist](-isValid) or is [invisible](-isVisible), `NO` otherwise.
 */
- (BOOL)isInvalidOrInvisible;

/**
 Determines whether the specified element is enabled.
 
 The user interface element represented by this element defines what
 "enabled" means. When the interface element is an instance of `UIControl`, 
 this returns the value of that control's `-isEnabled` property. 
 This method otherwise appears to evaluate to `YES`.

 @return `YES` if the user interface element represented by the specified element 
 is enabled, `NO` otherwise.
 
 @exception SLUIAElementInvalidException Raised if the element is not valid
 by the end of the [default timeout](+defaultTimeout).
 */
- (BOOL)isEnabled;

/**
 Determines whether it is possible to interact with the specified element.

 All methods that simulate user interaction with an element require that 
 that element be tappable. When a method involving user interaction is invoked 
 on an `SLUIAElement`, that method will wait up to the [default timeout](+defaultTimeout)
 for the element to become [valid](-isValid), and then will wait for the remainder
 of the timeout for the element to become tappable. If the element does not 
 become tappable within that interval, the method will raise an 
 `SLUIAElementNotTappableException`.
 
 This method returns, or raises an `SLUIAElementInvalidException`, immediately.
 
 Use of the `UIAElement` macro can help tests diagnose tappability failures.
 
 @warning [Visibility](-isVisible) correlates very closely with tappability, 
 but in some circumstances, an element may be tappable even if it is not visible, 
 and vice versa, due to bugs in UIAutomation. See the implementation for details.
 Tests should assert visibility separately if desired.
 
 @bug UIAutomation reports that scroll views are never tappable in applications 
 running on iPad simulators or devices running iOS 5.x. On such platforms, Subliminal 
 attempts to interact with scroll views despite UIAutomation reporting that they 
 are not tappable. Testing reveals that tapping scroll views on an iPad simulator 
 or device running iOS 5.x will fail, but dragging will succeed (barring factors 
 like the scroll view actually being hidden or having user interaction disabled, 
 etc.).
 
 UIAutomation correctly reports scroll view child elements as tappable 
 regardless of platform.

 @return `YES` if it is possible to tap on or otherwise interact with the user
 interface element represented by the specified element, `NO` otherwise.
 
 @exception SLUIAElementInvalidException Raised if the element is not currently
 valid.
 
 @see -isValid
 */
- (BOOL)isTappable;

/**
 Determines whether the specified element currently receives keyboard input.

 That is, whether the receiver is first responder.
 
 @return `YES` if the user interface element represented by the specified element 
 is the current receiver of keyboard input, `NO` otherwise.
 
 @exception SLUIAElementInvalidException Raised if the element is not currently
 valid.
 */
- (BOOL)hasKeyboardFocus;

#pragma mark - Gestures and Actions
/// ----------------------------------------
/// @name Gestures and Actions
/// ----------------------------------------

/**
 Taps the specified element.
 
 The tap occurs at the element's [hitpoint](-hitpoint).
 
 @bug This method will fail if the specified element identifies a scroll view
 in an application running on an iPad simulator or device running iOS 5.x, due 
 to a bug in UIAutomation (see -isTappable). An `SLUIAElementAutomationException`
 will be raised in such a scenario.
 
 UIAutomation is able to tap on scroll view child elements 
 regardless of platform.

 @exception SLUIAElementInvalidException Raised if the element is not valid
 by the end of the [default timeout](+defaultTimeout).
 
 @exception SLUIAElementNotTappableException Raised if the element is not tappable 
 when whatever amount of time remains of the default timeout after the element 
 becomes valid elapses.
 */
- (void)tap;

/**
 Double-taps the specified element.
 
 @bug This method will fail if the specified element identifies a scroll view
 in an application running on an iPad simulator or device running iOS 5.x, due
 to a bug in UIAutomation (see -isTappable). An `SLUIAElementAutomationException`
 will be raised in such a scenario.

 UIAutomation is able to double-tap scroll view child elements
 regardless of platform.
 
 @exception SLUIAElementInvalidException Raised if the element is not valid
 by the end of the [default timeout](+defaultTimeout).

 @exception SLUIAElementNotTappableException Raised if the element is not tappable
 when whatever amount of time remains of the default timeout after the element
 becomes valid elapses.
 */
- (void)doubleTap;

/**
 Touches and holds the specified element.

 @param duration The duration for the touch.
 */
- (void)touchAndHoldWithDuration:(NSTimeInterval)duration;

/**
 Drags within the bounds of the specified element.
 
 Each offset specifies a pair of _x_ and _y_ values, each ranging from `0.0` to `1.0`.
 These values represent, respectively, relative horizontal and vertical positions 
 within the element's `-rect`, with `{0.0, 0.0}` as the top left and `{1.0, 1.0}` 
 as the bottom right.

 This method uses a drag duration of 1.0 seconds (the documented default duration 
 for touch-and-hold gestures according to Apple's `UIAElement` class reference).
 
 @bug On simulators running iOS 7.x, UIAutomation drag gestures do not cause
 scroll views to scroll. Instances of `SLElement` are able to work around this; 
 instances of `SLStaticElement` are not.

 @param startOffset The offset, within the element's rect, at which to begin 
 dragging.
 @param endOffset The offset, within the element's rect, at which to end dragging.

 @exception SLUIAElementInvalidException Raised if the element is not valid
 by the end of the [default timeout](+defaultTimeout).

 @exception SLUIAElementNotTappableException Raised if the element is not tappable
 when whatever amount of time remains of the default timeout after the element
 becomes valid elapses.
 */
- (void)dragWithStartOffset:(CGPoint)startOffset endOffset:(CGPoint)endOffset;

#pragma mark - Identifying Elements
/// ----------------------------------------
/// @name Identifying Elements
/// ----------------------------------------

/**
 If this element has a UIScrollView or UIWebview ancestor, then that ancestor will be
 scrolled until this element is visible.
 
 @warning This method should only be called on elements that are within a UIScrollView or UIWebView.
 
 @exception SLUIAElementAutomationException if the element is not within a UIScrollView or UIWebView
 */
- (void)scrollToVisible;

/**
 Returns the element's label.

 @return The accessibility label of the user interface element represented by
 the specified element.

 @exception SLUIAElementInvalidException Raised if the element is not valid
 by the end of the [default timeout](+defaultTimeout).
 */
- (NSString *)label;

/**
 Returns the element's value.
 
 @return The accessibility value of the user interface element represented by
 the specified element.
 
 @exception SLUIAElementInvalidException Raised if the element is not valid
 by the end of the [default timeout](+defaultTimeout).
 */
- (NSString *)value;

#pragma mark - Determining Element Positioning
/// ----------------------------------------
/// @name Determining Element Positioning
/// ----------------------------------------

/**
 Returns the screen position to tap for the element.
 
 Below iOS 7, this defaults to the midpoint of the element's `-rect`;
 at or above iOS 7, this defaults to the element's [accessibility activation point](-[NSObject (UIAccessibility) accessibilityActivationPoint]).
 
 If the default hitpoint cannot be tapped, this method returns an alternate point, if possible.
 
 @return The position to tap for the user interface element represented by the 
 specified element, in screen coordinates, or `SLCGPointNull` if such a position 
 cannot be determined.
 
 @exception SLUIAElementInvalidException Raised if the element is not valid
 by the end of the [default timeout](+defaultTimeout).
 */
- (CGPoint)hitpoint;

/**
 Returns the location and size of the object.

 The relevant coordinates are screen-relative and are adjusted to account for 
 device orientation.

 @return The accessibility frame of the user interface element represented by 
 the specified element.
 
 @exception SLUIAElementInvalidException Raised if the element is not valid
 by the end of the [default timeout](+defaultTimeout).
 */
- (CGRect)rect;

#pragma mark - Logging Element Information
/// ----------------------------------------
/// @name Logging Element Information
/// ----------------------------------------

/**
 Logs information about the specified element.
 
 The information that is logged is determined by UIAutomation.

 @exception SLUIAElementInvalidException Raised if the element is not valid
 by the end of the [default timeout](+defaultTimeout).

 @see -[NSObject slAccessibilityDescription]
 */
- (void)logElement;

/**
 Logs information about the element hierarchy rooted in the specified
 element.
 
 The information that is logged is determined by UIAutomation.
 
 @exception SLUIAElementInvalidException Raised if the element is not valid
 by the end of the [default timeout](+defaultTimeout).

 @see -[NSObject slRecursiveAccessibilityDescription]
 */
- (void)logElementTree;

#pragma mark - Screenshots
/// ----------------------------------------
/// @name Screenshot an element
/// ----------------------------------------

/**
 Takes a screenshot of the specified element.

 The image is viewable from the UIAutomation debug log in Instruments.

 When running `subliminal-test` from the command line, the images are also saved
 as PNGs within the specified output directory.

 @param filename An optional string to use as the name for the resultant image file (provide nil to use a generic name.).

 @exception SLUIAElementInvalidException Raised if the element is not valid
 by the end of the [default timeout](+defaultTimeout).

 */

- (void)captureScreenshotWithFilename:(NSString *)filename;

@end


#pragma mark - Constants

/// All exceptions thrown by SLUIAElement will have names beginning with this prefix.
extern NSString *const SLUIAElementExceptionNamePrefix;

/// Thrown if an element is messaged while it is [invalid](-isValid).
extern NSString *const SLUIAElementInvalidException;

/// Thrown if tests attempt to simulate user interaction with an element
/// while that element is not [tappable](-isTappable).
extern NSString *const SLUIAElementNotTappableException;

/// Thrown if the Automation instrument is unable to interpret a command from the tests.
extern NSString *const SLUIAElementAutomationException;

/// `SLUIAElement` waits for this duration between checks of an element's
/// validity, tappability, etc.
extern const NSTimeInterval SLUIAElementWaitRetryDelay;

/// Represents an invalid CGPoint.
extern const CGPoint SLCGPointNull;

/// Returns YES if `point` is the null point, NO otherwise.
extern BOOL SLCGPointIsNull(CGPoint point);
