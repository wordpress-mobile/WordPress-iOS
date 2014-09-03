//
//  SLAccessibilityPath.h
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


@class SLElement;
@class SLAccessibilityPath;

/**
 */
@interface NSObject (SLAccessibilityPath)

/**
 Returns the accessibility path from this object to the object
 [matching](-[SLElement matchesObject:]) the specified element.

 The first component in the path is the receiver, and the last component
 is an object matching the specified element.

 @param element The element to be matched.
 @return A path that can used by UIAutomation to access element or `nil`
 if an object matching _element_ is not found within the accessibility hierarchy
 rooted in the receiver.
 */
- (SLAccessibilityPath *)slAccessibilityPathToElement:(SLElement *)element;

@end


/**
 `SLAccessibilityPath` represents a path through an accessibility hierarchy
 from an accessibility container to one of its (potentially distant) children.

 Once a path is found between a parent and child object using
 `-[NSObject slAccessibilityPathToElement:]`, it can then be
 [serialized into Javascript](-UIARepresentation) in order to identify,
 access, and manipulate the `UIAElement` corresponding to the child when
 [evaluated](-[SLTerminal eval:]) as part of a larger expression.

 @warning `SLAccessibilityPath` is designed for use from background threads.
 Because its components are likely `UIKit` objects, `SLAccessibilityPath`
 holds weak references to those components. Clients should be prepared
 to handle nil [path components](-examineLastPathComponent:) or invalid
 [UIAutomation representations](-UIARepresentation) in the event that a path
 component drops out of scope.
 */
@interface SLAccessibilityPath : NSObject

#pragma mark - Examining the Path's Destination
/// ----------------------------------------
/// @name Examining the Path's Destination
/// ----------------------------------------

/**
 Allows the caller to interact with the last path component of the receiver.

 Path components are objects at successive levels of an accessibility hierarchy
 (where the component at index `i + 1` is the child of the component at index `i`).
 The last path component is the object at the deepest level of such a hierarchy,
 i.e. the destination of the path.

 The block will be executed synchronously on the main thread.

 @param block A block which takes the last path component of the receiver
 as an argument and returns void. The block may invoked with a `nil` argument
 if the last path component has dropped out of scope between the receiver being
 constructed and it receiving this message.
 */
- (void)examineLastPathComponent:(void (^)(NSObject *lastPathComponent))block;

#pragma mark - Serializing the Path
/// ----------------------------------------
/// @name Serializing the Path
/// ----------------------------------------

/**
 Binds the components of the receiver to unique `UIAElement` instances
 for the duration of the method.

 This is done by modifying the components' accessibility properties in such a
 way as to make the names (`UIAElement.name()`) of their corresponding `UIAElement`
 instances unique. With the modifications in place, the block provided is then
 evaluated, on the calling thread, with the receiver. The modifications are then
 reset.

 @param block A block which takes the bound receiver as an argument and returns
 `void`.

 @see -UIARepresentation
 */
- (void)bindPath:(void (^)(SLAccessibilityPath *boundPath))block;

/**
 Returns the representation of the path as understood by UIAutomation.

 This method operates by serializing the objects constituting the path's components
 as references into successive instances of `UIElementArray`, the outermost of
 which is contained by the main window. That is, this method creates a JavaScript
 expression of the form:

    UIATarget.localTarget().frontMostApp().mainWindow().elements()[...].elements()[...]...

 Each reference into a `UIAElementArray` (within brackets) is by element name
 (`UIAElement.name()`). Any components that the receiver was unable to name
 (e.g. components which have dropped out of scope between the receiver being
 constructed and it receiving this message) will be serialized as `elements()["(null)"]`.

 @warning To guarantee that each `UIAElementArray` reference will uniquely identify
 the corresponding component of the receiver, this method must only be called
 while the receiver is [bound](-bindPath:).

 @bug This method should not assume that the path identifies elements within
 the main window.

 @return A JavaScript expression that represents the absolute path to the `UIAElement`
 corresponding to the last component of the receiver.
 */
- (NSString *)UIARepresentation;

@end
