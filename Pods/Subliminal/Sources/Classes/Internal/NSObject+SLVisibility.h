//
//  NSObject+SLVisibility.h
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
 The methods in the `NSObject (SLVisibility)` category allow Subliminal 
 to determine if an object is visible on the screen.
 */
@interface NSObject (SLVisibility)

/**
 Determines if the specified object is visible on the screen.

 @bug This method always returns `NO` if the device is in a non-portrait
 orientation: https://github.com/inkling/Subliminal/issues/135 .

 @return YES if the receiver is visible within the accessibility hierarchy,
 NO otherwise.
 */
- (BOOL)slAccessibilityIsVisible;

@end
