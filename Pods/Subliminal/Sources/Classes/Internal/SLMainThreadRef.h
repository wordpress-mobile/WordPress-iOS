//
//  SLMainThreadRef.h
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
 An `SLMainThreadRef` helps a background thread to safely manage its reference to
 an object that is only safe to access from the main thread (e.g. an instance 
 of a `UIKit` class) by:
 
 1. weakly referencing that object (the "target"), so that the background
    thread does not keep the target alive past its release by the main thread; and
 2. only permitting access to the target on the main thread.

 */
@interface SLMainThreadRef : NSObject

/**
 Creates and returns a reference to the specified target.
 
 @param target An object retrieved from the main thread.
 @return A newly created reference.
 */
+ (instancetype)refWithTarget:(id)target;

/**
 Returns the receiver's target.
 
 This may only be called from the main thread.

 @return The receiver's target, or `nil` if the target has been released 
 by the main thread.
 
 @exception NSInternalInconsistencyException Thrown if this method is called 
 from the main thread.
 */
- (id)target;

@end
