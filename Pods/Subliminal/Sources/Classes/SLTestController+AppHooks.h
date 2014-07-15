//
//  SLTestController+AppHooks.h
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

#import <Subliminal/Subliminal.h>

/**
 Tests execute on a background queue. The methods in the `SLTestController (AppHooks)` 
 category allow tests to access and manipulate application state in a structured,
 thread-safe manner.
 
 For instance, before running the tests, the application delegate could register
 a "login manager" singleton as being able to programmatically log a test user in:

     [[SLTestController sharedTestController] registerTarget:[LoginManager sharedManager] 
                                                   forAction:@selector(logInWithInfo:)];
 
 When tests need to log in, they could then call `loginWithInfo:`:
 
    [[SLTestController sharedTestController] sendAction:@selector(logInWithInfo:)
                                             withObject:@{
                                                            @"username": @"john@foo.com",
                                                            @"password": @"Hello1234"
                                                         }];
 
 This technique has two main benefits:
 
 1. It increases the independence of the tests: while one test could (and should)
    test logging in as a user would, using the UI, the other tests could
    use the programmatic interface, and not be crippled should the log-in
    UI break.
 2. It encourages re-use of your application's code, while not making the
    tests dependent on your application's structure: in the example above,
    the tests need not know which object implements the `logInWithInfo:`
    action. And, actions can only return objects that can be copied into the
    testing context, preventing the application and tests from sharing state.

 Target actions may be conditionally defined (and registered) only when
 integration testing by using the `INTEGRATION_TESTING` preprocessor macro.
 */
@interface SLTestController (AppHooks)

#pragma mark - Registering and Deregistering App Hooks
/// ------------------------------------------------------
/// @name Registering and Deregistering App Hooks
/// ------------------------------------------------------

/**
 Allows application objects to register themselves as being able to perform 
 arbitrary actions.

 Action messages must take either no arguments, or one id-type value conforming 
 to `NSCopying`. Messages can return either nothing, or id-type values conforming
 to `NSCopying`. (Copying arguments and return values prevents the tests and 
 the application from sharing state.)

 Each action is performed on the main thread.
 The argument (if any) is copied, and the copy passed to the target.
 The return value (if any) is copied, and the copy passed to the caller.
 
 Only one target may be registered for any given action:
 if a second target is registered for a given action,
 the first target will be deregistered for that action.
 Registering the same target for the same action twice has no effect.

 The test controller keeps weak references to targets. It's still recommended
 for targets to deregister themselves at appropriate times, though.

 @param target The object to which the action message will be sent.
 @param action The message which will be sent to the target.
 It must take either no arguments, or one `id`-type value conforming to NSCopying.
 It must return either nothing, or an id-type value conforming to NSCopying.
 
 @see -deregisterTarget:
 */
- (void)registerTarget:(id)target forAction:(SEL)action;

/**
 Deregisters the target for the specified actions.

 If target is not registered for the specified action, this method has no effect.

 @param target The object to be deregistered.
 @param action The action message for which the target should be deregistered.
 */
- (void)deregisterTarget:(id)target forAction:(SEL)action;

/**
 Deregisters the target for all actions.

 If target is not registered for any actions, this method has no effect.

 @param target The object to be deregistered.
 */
- (void)deregisterTarget:(id)target;

#pragma mark - Calling App Hooks
/// ----------------------------------------
/// @name Calling App Hooks
/// ----------------------------------------

/**
 Sends a specified action message to its registered target and returns the result of the message.

 This method must not be called from the main thread (it is intended to be called
 by tests).
 
 The message will be performed on the main thread.
 The returned value (if any) will be copied, and the copy passed to the caller.

 @param action The message to be performed.
 @return The result of the action, if any; otherwise `nil`.
 
 @exception SLAppActionTargetDoesNotExistException Thrown if, after several 
 seconds' wait, no target has been registered for _action_, or a registered target
 has fallen out of scope.
 */
- (id)sendAction:(SEL)action;

/**
 Sends a specified action message to its registered target with an object as the argument,
 and returns the result of the message.

 This method must not be called from the main thread (it is intended to be called
 by tests).

 The message will be performed on the main thread.
 The argument will be copied, and the copy passed to the target.
 The returned value (if any) will be copied, and the copy passed to the calling SLTest.

 @param action The message to be performed.
 @param object An object which is the sole argument of the action message.
 @return The result of the action, if any; otherwise nil.

 @exception SLAppActionTargetDoesNotExistException Thrown if, after several 
 seconds' wait, no target has been registered for _action_, or a registered target
 has fallen out of scope.
 */
- (id)sendAction:(SEL)action withObject:(id<NSCopying>)object;

#pragma mark - Convenience Macros

/**
 The `SLAskApp` macro provides a compact syntax for calling an application hook.
 
 It allows you to "ask" the app to perform some action and potentially return a value.

 @param selName The name of the app hook's action selector.
 */
#define SLAskApp(selName) [[SLTestController sharedTestController] sendAction:@selector(selName)]

/**
 The `SLAskApp1` macro provides a compact syntax for calling an application hook
 which takes an argument.

 @param selName The name of the app hook's action selector.
 @param arg An argument to pass along with the app hook action.
 */
#define SLAskApp1(selName, arg) [[SLTestController sharedTestController] sendAction:@selector(selName) withObject:arg]

/**
 The `SLAskAppYesNo` macro provides a compact syntax for calling an application hook
 which returns an `NSNumber` representing a Boolean value.
 
 This is useful in conjunction with the test assertion macros:
 
    SLAssertTrue(SLAskAppYesNo(isUserLoggedIn), @"User is not logged in.")
 
 @param selName The name of the app hook's action selector.
 */
#define SLAskAppYesNo(selName) [SLAskApp(selName) boolValue]

/**
 The `SLAskApp1` macro provides a compact syntax for calling an application hook
 which takes an argument and returns an `NSNumber` representing a Boolean value.

 This is useful in conjunction with the test assertion macros:

     SLAssertTrue(SLAskAppYesNo1(isBookDownloaded:, bookID), @"Book is not downloaded.")

 @param selName The name of the app hook's action selector.
 @param arg An argument to pass along with the app hook action.
 */
#define SLAskAppYesNo1(selName, arg) [SLAskApp1(selName, arg) boolValue]

@end


#pragma mark - Constants

/// Thrown if the test controller is asked to send an action for which no target is registered.
extern NSString *const SLAppActionTargetDoesNotExistException;
