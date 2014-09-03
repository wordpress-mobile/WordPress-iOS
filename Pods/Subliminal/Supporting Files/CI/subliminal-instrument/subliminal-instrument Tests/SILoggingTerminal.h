//
//  SILoggingTerminal.h
//  subliminal-instrument
//
//  For details and documentation:
//  http://github.com/inkling/Subliminal
//
//  Copyright 2014 Inkling Systems, Inc.
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
 `SILoggingTerminal` is designed to intercept and report messages
 logged to UIAutomation by `SLLogger` by mocking `SLTerminal`.

 To use `SILoggingTerminal`, retrieve the [shared instance](-sharedTerminal)
 and call `-beginMocking`. The logging terminal will then post an instance of
 `SILoggingTerminalMessageLoggedNotification` every time that the
 [shared logger](+[SLLogger sharedLogger]) is asked to log a message.
 */
@interface SILoggingTerminal : NSObject

/**
 The shared logging terminal.
 
 @return The shared logging terminal.
 */
+ (instancetype)sharedTerminal;

/**
 Begin mocking the [shared terminal](+[SLTerminal sharedTerminal]).
 
 @warning The receiver will intercept all calls to `-[SLTerminal eval:]`
          until `-stopMocking` is called.
 */
- (void)beginMocking;

/**
 Stops mocking the [shared terminal](+[SLTerminal sharedTerminal]).
 */
- (void)stopMocking;

@end


/**
 Posted when the [shared logger](+[SLLogger sharedLogger])
 attempts to log a message to UIAutomation.
 The [_userInfo_ dictionary](-[NSNotification userInfo]) contains
 one key, `SILoggingTerminalMessageUserInfoKey`.
 */
extern NSString *const SILoggingTerminalMessageLoggedNotification;

/**
 The key for an `NSString` object which is the message logged by
 the [shared logger](+[SLLogger sharedLogger]).
 */
extern NSString *const SILoggingTerminalMessageUserInfoKey;
