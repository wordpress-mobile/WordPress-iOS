//
//  SLUIAElement+Subclassing.h
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

#import "SLUIAElement.h"
#import "SLElement.h"
#import "SLLogger.h"
#import "SLTerminal.h"
#import "SLTerminal+ConvenienceFunctions.h"
#import "SLStringUtilities.h"

/**
 The methods in the `SLUIAElement (Subclassing)` category are to be called 
 or overridden by subclasses of `SLUIAElement`. Tests should not call these 
 methods.
 */
@interface SLUIAElement (Subclassing)

#pragma mark - Methods for Subclasses
/// -------------------------------------------
/// @name Methods for Subclasses
/// -------------------------------------------

/**
 Forwards an action message to the `UIAElement` corresponding to the 
 specified element and returns the result.
 
 The "message" is a formatted function call. For instance, `SLUIAElement` calls 
 `tap()` on its corresponding `UIAElement` by invoking
 
    [self waitUntilTappable:YES thenSendMessage:@"tap()"]
 
 This method automatically waits until the element [is valid](-isValid) before
 attempting to access the `UIAElement`, for not more than the [default timeout](+defaultTimeout).
 If _waitUntilTappable_ is `YES`, the method will also wait, for the remainder
 of the timeout, for the element to become [tappable](-isTappable).
 
 @warning All methods that involve user interaction must pass `YES` for 
 _waitUntilTappable_.
 
 @warning Variable arguments that are strings need to be escaped,
 using `-[NSString slStringByEscapingForJavaScriptLiteral]`,
 if they are to be substituted into a JavaScript string literal.

 @param waitUntilTappable If `YES`, and `-canDetermineTappability` returns `YES`, 
 this method will wait for the remainder of the default timeout, after the element
 becomes valid, for the element to become tappable.
 @param action A format string (in the manner of `-[NSString stringWithFormat:]`) 
 representing a JavaScript function to be called on the corresponding `UIAElement`.
 @param ... (Optional) A comma-separated list of arguments to substitute into 
 `action`.
 @return The value returned by the function, as an Objective-C object. See 
 `-[SLTerminal eval:]` for more infomation.
 
 @exception SLUIAElementInvalidException Raised if the element is not valid
 by the end of the default timeout.

 @exception SLUIAElementNotTappableException Raised if the element waits for
 tappability and is not tappable when whatever amount of time remains of the 
 default timeout, after the element becomes valid, elapses.
 */
- (id)waitUntilTappable:(BOOL)waitUntilTappable
        thenSendMessage:(NSString *)action, ... NS_FORMAT_FUNCTION(2, 3);

/**
 Provides access to the UIAutomation representation of the specified element 
 within a specified block.
 
 The UIAutomation representation identifies the `UIAElement` corresponding to 
 the specified element to UIAutomation.

 This method allows an element to evaluate more complex JavaScript expressions 
 involving its corresponding `UIAElement` than simple function calls (for which
 `-waitUntilTappable:thenSendMessage:` may be used); or to use a non-standard
 timeout for resolving the corresponding `UIAElement`.

 This method waits until the element [is valid](-isValid) before attempting to 
 access the `UIAElement`, for not more than _timeout_. If _waitUntilTappable_
 is `YES`, the method will also wait, for the remainder of _timeout_, for the
 element to become [tappable](-isTappable).

 @warning If the expression to be evaluated by _block_ involves user interaction,
 the caller must pass `YES` for _waitUntilTappable_.

 @param waitUntilTappable If `YES`, and `-canDetermineTappability` returns `YES`, 
 this method will wait for the remainder of _timeout_, after the element becomes valid,
 for the element to become tappable.
 @param block A block which takes the UIAutomation representation of the specified 
 element as an argument and returns `void`.
 @param timeout The timeout for which this method should wait for the specified 
 element to become valid (and tappable, if _waitUntilTappable_ is `YES`). Clients
 should generally call this method with `+[SLUIAElement defaultTimeout]`.
 
 @exception SLUIAElementInvalidException Raised if the element is not valid
 by the end of _timeout_.

 @exception SLUIAElementNotTappableException Raised if the element waits for 
 tappability and is not tappable when whatever amount of time remains of _timeout_,
 after the element becomes valid, elapses.
 */
- (void)waitUntilTappable:(BOOL)waitUntilTappable
        thenPerformActionWithUIARepresentation:(void(^)(NSString *UIARepresentation))block
                                       timeout:(NSTimeInterval)timeout;

/**
 Returns the name of the JavaScript function used to evaluate whether a
 `UIAElement` is tappable, loading it into the terminal's namespace if necessary.
 
 This method is used internally by `SLUIAElement` and its subclasses 
 `SLElement` and `SLStaticElement`. It should not need to be used by additional 
 descendants of `SLUIAElement`.
 
 @return The name of the JavaScript function used to evaluate whether a 
 `UIAElement` is tappable.
 */
+ (NSString *)SLElementIsTappableFunctionName;

/**
 Determines whether the specified element's response to `-isTappable` is valid.
 
 This should return `YES` unless the specified element identifies an instance 
 of `UIScrollView` and tests are running on an iPad simulator or device running 
 iOS 5.x. On those platforms, UIAutomation reports that scroll views are always 
 invisible, and thus not tappable.
 
 If this method returns `NO`, tappability will not be enforced as a prerequisite 
 for simulating user interaction. This will let Subliminal attempt interaction 
 with scroll views despite UIAutomation's response. Testing reveals that certain 
 forms of interaction, e.g. dragging, will yet succeed (barring factors like the 
 scroll view actually being hidden or having user interaction disabled, etc.).
 
 @exception SLUIAElementInvalidException Raised if the element is not valid.
 */
- (BOOL)canDetermineTappability;

@end


/**
 The methods in the `SLElement (Subclassing)` category are to be called or
 overridden by subclasses of `SLElement`. Tests should not call these methods.
 */
@interface SLElement (Subclassing)

#pragma mark - Methods for Subclasses
/// -------------------------------------------
/// @name Methods for Subclasses
/// -------------------------------------------

/**
 Determines if the specified element matches the specified object.

 Subclasses of `SLElement` can override this method to provide custom matching behavior.
 The default implementation evaluates the object against the predicate
 with which the element was constructed (i.e. the argument to
 `+elementMatching:withDescription:`, or a predicate derived from the arguments
 to a higher-level constructor).
 
 If you override this method, you must call `super` in your implementation.

 @param object The object to which the instance of `SLElement` should be compared.
 @return `YES` if the specified element matches `object`, `NO` otherwise.
 */
- (BOOL)matchesObject:(NSObject *)object;

/**
 Allows the caller to interact with the actual object matched by the specified 
 `SLElement`.

 The block will be executed synchronously on the main thread.

 This method should be used only when UIAutomation offers no API providing 
 equivalent functionality: as a user interface element, the object should be 
 manipulated by the simulated user for the tests to be most accurate.

 @param block A block which takes the matching object as an argument and returns 
 `void`.
 
 @exception SLUIAElementInvalidException Raised if the element has not matched 
 an object by the end of the [default timeout](+[SLUIAElement defaultTimeout]).
 */
- (void)examineMatchingObject:(void (^)(NSObject *object))block;

@end
