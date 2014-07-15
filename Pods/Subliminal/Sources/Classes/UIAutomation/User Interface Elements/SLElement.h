//
//  SLElement.h
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

/**
 Instances of `SLElement` allow you to access and manipulate user interface
 elements that match criteria such as having certain accessible values
 or being of a particular type of control.

 These criteria are specified when `SLElement` is constructed, in the form of a
 predicate. When `SLElement` needs to access its corresponding interface element,
 it evaluates the element hierarchy using that predicate. If a matching object
 is found, it is made available to Subliminal and to UIAutomation
 to access and manipulate.
 */
@interface SLElement : SLUIAElement

#pragma mark - Matching Interface Elements
/// -------------------------------------------
/// @name Matching Interface Elements
/// -------------------------------------------

/**
 Creates and returns an element that matches objects in the accessibility hierarchy
 with the specified accessibility label.

 An accessibility label is the preferred way to identify an element to Subliminal, 
 because accessibility labels are visible to users of assistive applications.
 See the [UIAccessibility Protocol Reference](https://developer.apple.com/library/ios/documentation/uikit/reference/UIAccessibility_Protocol/Introduction/Introduction.html) 
 for guidance in determining appropriate labels.

 @param label A label that identifies a matching object.
 @return A newly created element that matches objects in the accessibility
 hierarchy with the specified accessibility label.
 */
+ (instancetype)elementWithAccessibilityLabel:(NSString *)label;

/**
 Creates and returns an element that matches objects in the accessibility hierarchy
 with the specified accessibility label, value, and/or traits.

 See the [UIAccessibility Protocol Reference](https://developer.apple.com/library/ios/documentation/uikit/reference/UIAccessibility_Protocol/Introduction/Introduction.html) 
 for guidance in determining appropriate accessibility labels, values, and traits.
 
 @param label A label that identifies a matching object. 
 If this is `nil`, the element does not restrict matches by label.
 @param value The value of a matching object. 
 If this is `nil`, the element does not restrict matches by value.
 @param traits The combination of accessibility traits that characterize a 
 matching object. If this is `SLUIAccessibilityTraitAny`, the element does not 
 restrict matches by trait.
 */
+ (instancetype)elementWithAccessibilityLabel:(NSString *)label value:(NSString *)value traits:(UIAccessibilityTraits)traits;

/**
 Creates and returns an element that matches objects in the accessibility hierarchy
 with the specified accessibility identifier.

 It is best to identify an object using information like its accessibility label,
 value, and/or traits, because that information also helps users with disabilities
 use your application. However, when that information is not sufficient to
 identify an object, an accessibility identifier may be set by the application. 
 Unlike accessibility labels, identifiers are not visible to users of assistive 
 applications.

 @param identifier A string that uniquely identifies a matching object.
 @return A newly created element that matches objects in the accessibility
 hierarchy with the specified accessibility identifier.
 */
+ (instancetype)elementWithAccessibilityIdentifier:(NSString *)identifier;

/**
 Creates and returns an element that evaluates the accessibility hierarchy
 using a specified block object.

 This method allows you to apply some knowledge of the target object's identity
 and/or its location in the accessibility hierarchy, where the target object's 
 accessibility information is not sufficient to distinguish the object.

 Consider using one of the more specialized constructors before this method.
 It is best to identify an object using information like its accessibility label, 
 value, and/or traits, because that information also helps users with disabilities 
 use your application. Even when that information is not sufficient to distinguish 
 a target object, it may be easier for your application to set a unique
 accessibility identifier on a target object than for your tests to define a 
 complex predicate.

 To describe the element's location in the accessibility hierarchy, see the 
 methods in `NSObject (SLAccessibilityHierarchy)`.

 @param predicate The block used to evaluate objects within the accessibility 
 hierarchy. The block will be evaluated on the main thread. The block should 
 return YES if the element matches the object, otherwise NO.
 @param description An optional description of the element, for use in debugging.
 (The other `SLElement` constructors derive element descriptions from their arguments.)
 @return A newly created element that evaluates objects using predicate.
 
 @see +elementWithAccessibilityIdentifier:
 */
+ (instancetype)elementMatching:(BOOL (^)(NSObject *obj))predicate withDescription:(NSString *)description;

/**
 Creates and returns an element that matches any object in the accessibility hierarchy.

 SLElement defines this constructor primarily for the benefit of subclasses
 that match a certain kind of object by default, such that a match is likely
 unique even without the developer specifying additional information. For instance,
 if your application only has one webview onscreen at a time, you could match
 that webview (using `SLWebView`) by matching "any" webview, without having to
 give that webview an accessibility label or identifier.

 @return A newly created element that matches any object in the accessibility hierarchy.
 */
+ (instancetype)anyElement;

#pragma mark - Gestures and Actions
/// ------------------------------------------
/// @name Gestures and Actions
/// ------------------------------------------

/**
 Taps the specified element at its activation point.
 
 The activation point is by default the midpoint of the accessibility element's 
 frame (`[-rect](-[SLUIAElement rect])`), but the activation point may be modified
 to direct VoiceOver to tap at a different point. See
 `-[NSObject (UIAccessibility) accessibilityActivationPoint]` for more information
 and examples.
 
 This method is most useful when running against SDKs older than iOS 7,
 because on those platforms, `[-hitpoint](-[SLUIAElement hitpoint])` and thus
 `[-tap](-[SLUIAElement tap])` ignore the value of the element's accessibility
 activation point. On or above iOS 7, `-hitpoint` respects the value of the
 accessibility activation point and so `-tap` and this method are equivalent.
 */
- (void)tapAtActivationPoint;

#pragma mark - Logging Element Information
/// ----------------------------------------
/// @name Logging Element Information
/// ----------------------------------------

/**
 Logs information about the specified element.

 `SLElement` overrides this method to describe the application object
 corresponding to the specified element, which allows `SLElement` to 
 provide additional information beyond that logged by the superclass' implementation.

 @exception SLUIAElementInvalidException Raised if the element is not valid
 by the end of the [default timeout](+[SLUIAElement defaultTimeout]).
 */
- (void)logElement;

@end


#pragma mark - Constants

/// Used with `+[SLElement elementWithAccessibilityLabel:value:traits:]`
/// to match elements with any combination of accessibility traits.
extern UIAccessibilityTraits SLUIAccessibilityTraitAny;


/**
 The methods in the `SLElement (DebugSettings)` category may be useful in debugging Subliminal.
 */
@interface SLElement (DebugSettings)

#pragma mark - Debugging Subliminal
/// -------------------------------------------
/// @name Debugging Subliminal
/// -------------------------------------------

/**
 Determines whether the specified element should use UIAutomation to confirm that it [is valid](-isValid)
 after Subliminal has determined (to the best of its ability) that it is valid.
 
 If Subliminal misidentifies an element to UIAutomation, UIAutomation will not necessarily raise 
 an exception but instead may silently fail (e.g. it may return `null` from APIs like `UIAElement.hitpoint()`, 
 causing Subliminal to think that an element isn't tappable when really it's not valid). 
 Enabling this setting may help in diagnosing such failures.
 
 Validity double-checking is disabled (`NO`) by default, because it is more likely that there is a bug 
 in a particular test than a bug in Subliminal, and because enabling double-checking will 
 negatively affect the performance of the tests. 
 */
@property (nonatomic) BOOL shouldDoubleCheckValidity;

@end
