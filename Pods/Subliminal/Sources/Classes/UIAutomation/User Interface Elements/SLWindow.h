//
//  SLWindow.h
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

#import "SLElement.h"

/**
 `SLWindow` matches instances of `UIWindow`.
 
 In particular, the singleton `+mainWindow` instance matches the application's 
 main window.
 */
@interface SLWindow : SLElement

/**
 Returns an object that represent's the application's main window.
 
 This is the window that is currently the key window (`-[[UIApplication sharedApplication] keyWindow]`).
 */
+ (SLWindow *)mainWindow;

@end
