//
//  NSObject+SLAccessibilityDescription.h
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

/**
 The methods in the `NSObject (SLAccessibilityDescription)` category allow developers
 to examine the accessibility properties of objects within their application, 
 for use in making their application accessible to disabled users and to 
 Subliminal.
 */
@interface NSObject (SLAccessibilityDescription)

/**
 Returns a string that describes the receiver in terms of its accessibility properties.

 @return A string that describes the receiver in terms of its accessibility properties.
 */
- (NSString *)slAccessibilityDescription;

/**
 Returns a string that recursively describes accessibility elements contained
 within the receiver.

 In terms of their accessibility properties, using `-slAccessibilityDescription`.

 If the receiver is a `UIView`, this also enumerates the subviews of the receiver.

 @warning This method describes all elements contained within the receiver,
 even if they will not appear in the accessibility hierarchy (see
 `-[NSObject willAppearInAccessibilityHierarchy]`). That is, the set of
 elements described by this method is a superset of those elements that will
 appear in the accessibility hierarchy. To log only those elements that will
 appear in the accessibility hierarchy, use `-[SLUIAElement logElementTree]`.

 @return A string that recursively describes the receiver and its accessibility
 children in terms of their accessibility properties.
 */
- (NSString *)slRecursiveAccessibilityDescription;

@end
