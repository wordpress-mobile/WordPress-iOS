//
//  NSObject+SLAccessibilityHierarchy.h
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

/**
 The methods in the `NSObject (SLAccessibilityHierarchy)` category
 allow Subliminal and 3rd-party developers to examine the accessibility hierarchy
 --a subset of the hierarchy formed by views and the accessibility elements
 they vend.
 
 3rd-party developers might use the methods in this category to determine
 why an interface element is not accessible: see `-willAppearInAccessibilityHierarchy`.
 
 3rd-party developers might use the methods in "Navigating the Accessibility Hierarchy" 
 to develop [predicates](-[SLElement elementMatching:withDescription:]) that 
 match elements at particular positions in the accessibility hierarchy, as 
 an alternative to setting accessibility identifiers, when no other accessibility 
 information is available.
 */
@interface NSObject (SLAccessibilityHierarchy)

#pragma mark - Determining Whether An Element Will Appear In the Accessibility Hierarchy
/// ----------------------------------------------------------------------------------
/// @name Determining Whether An Element Will Appear In the Accessibility Hierarchy
/// ----------------------------------------------------------------------------------

/**
 Returns a Boolean value that indicates whether the receiver will appear
 in the accessibility hierarchy.
 
 The receiver will only be accessible to UIAutomation if it appears in the 
 hierarchy. Experimentation reveals that presence in the hierarchy is determined 
 by a combination of the receiver's accessibility information and its location 
 in the view hierarchy.
 
 See the method's implementation for specifics, or use the
 [Accessibility Inspector](https://developer.apple.com/library/ios/technotes/TestingAccessibilityOfiOSApps/TestAccessibilityiniOSSimulatorwithAccessibilityInspector/TestAccessibilityiniOSSimulatorwithAccessibilityInspector.html#//apple_ref/doc/uid/TP40012619-CH4):
 if it can read an element's information, some underlying object is present
 in the accessibility hierarchy.

 @return YES if the receiver will appear in the accessibility hierarchy,
 otherwise NO.
 */
- (BOOL)willAppearInAccessibilityHierarchy;

#pragma mark - Navigating the Accessibility Hierarchy
/// -----------------------------------------------
/// @name Navigating the Accessibility Hierarchy
/// -----------------------------------------------

/**
 Returns the SLAccessibility-specific accessibility container of the receiver.

 This method allows the developer to navigate upwards through the hierarchy 
 constructed by `-slChildAccessibilityElementsFavoringSubviews:`. That hierarchy 
 is not guaranteed to contain only those elements that will appear in the 
 accessibility hierarchy.

 @return The object's superview, if it is a `UIView`;
 otherwise its `accessibilityContainer`, if it is a `UIAccessibilityElement`;
 otherwise `nil`.
 
 @see -willAppearInAccessibilityHierarchy
 */
- (NSObject *)slAccessibilityParent;

/**
 Creates and returns an array of objects that are child accessibility elements
 of this object.

 If the receiver is a `UIView`, this will also include subviews.
 
 This method, applied recursively, will construct a hierarchy that includes 
 all accessibility elements and views of the receiver. This hierarchy is not 
 guaranteed to contain only those elements that will appear in the accessibility 
 hierarchy.

 @param favoringSubviews If YES, views should be placed before accessibility 
 elements in the returned array; otherwise, they will be placed afterwards.

 @return An array of objects that are child accessibility elements of this object.
 
 @see -willAppearInAccessibilityHierarchy
 */
- (NSArray *)slChildAccessibilityElementsFavoringSubviews:(BOOL)favoringSubviews;

/**
 Returns the index of the specified child element in the array of the
 child accessibility elements of the receiver.

 @param childElement A child accessibility element of the receiver.
 @param favoringSubviews If `YES`, subviews should be ordered before
 accessibility elements among the receiver's child accessibility elements;
 otherwise, they will be ordered afterwards.
 @return The index of the child element in the array of child accessibility 
 elements of the receiver.
 
 @see -slChildAccessibilityElementsFavoringSubviews:
 @see -slAccessibilityParent
 */
- (NSUInteger)slIndexOfChildAccessibilityElement:(NSObject *)childElement favoringSubviews:(BOOL)favoringSubviews;

/**
 Returns the child accessibility element of the receiver at the specified index.

 @param index The index of the child accessibility element to be returned.
 @param favoringSubviews If `YES`, subviews should be ordered before
 accessibility elements among the receiver's child accessibility elements;
 otherwise, they will be ordered afterwards.
 @return The child accessibility element at the specified index in the array 
 of the child accessibility elements of the receiver.
 
 @see -slChildAccessibilityElementsFavoringSubviews:
 @see -slAccessibilityParent
 */
- (NSObject *)slChildAccessibilityElementAtIndex:(NSUInteger)index favoringSubviews:(BOOL)favoringSubviews;

@end


/**
 The methods in the `UIView (SLAccessibility_Internal)` category describe
 criteria that determine whether mock views will appear in the accessibility 
 hierarchy.
 
 Mock views are elements that UIAccessibility uses to represent certain views 
 in the accessibility hierarchy rather than the views themselves.
 
 3rd-party developers should have no need to use these methods.
 */
@interface UIView (SLAccessibility_Internal)

/**
 Returns a Boolean value that indicates whether an object is a mock view.

 Mock views are accessibility elements created by the accessibility system
 to represent certain views like UITableViewCells. Where a mock view exists,
 the accessibility system, and UIAutomation, read/manipulate it instead of the
 real view.
 
 @param elementObject An object which may or may not be a mock view.
 @param viewObject An object which may or may not be a view.

 @return YES if viewObject is a UIView and elementObject is mocking that view, otherwise NO.
 */
+ (BOOL)elementObject:(id)elementObject isMockingViewObject:(id)viewObject;

/**
 Returns a Boolean value that indicates whether an object mocking the receiver
 will appear in an accessibility hierarchy.

 Experimentation reveals that a mock view will appear in the accessibility hierarchy
 if the real object will appear in any accessibility hierarchy (see
 `-[NSObject willAppearInAccessibilityHierarchy]`) or is an instance of one of a
 [certain set of classes](-classForcesPresenceOfMockingViewsInAccessibilityHierarchy).

 @return YES if an object mocking the receiver will appear in an accessibility
 hierarchy, otherwise NO.
 */
- (BOOL)elementMockingSelfWillAppearInAccessibilityHierarchy;

/**
 Returns a Boolean value that indicates whether the receiver's class
 forces the presence of mock views in the accessibility hierarchy.

 Experimentation reveals that objects mocking certain types of views will appear
 in UIAutomation's accessibility hierarchy regardless of their accessibility
 identification.

 @return YES if the receiver's class forces the presence of objects mocking
 instances of the class in an accessibility hierarchy, otherwise NO.
 */
- (BOOL)classForcesPresenceOfMockingViewsInAccessibilityHierarchy;

@end
