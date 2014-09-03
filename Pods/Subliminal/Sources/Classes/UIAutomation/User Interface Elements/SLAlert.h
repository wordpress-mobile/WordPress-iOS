//
//  SLAlert.h
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

#import <UIKit/UIKit.h>


/// Types of textfields contained by UIAlertViews, as determined by the
/// alert view's alertViewStyle.
typedef NS_ENUM(NSInteger, SLAlertTextFieldType) {
    SLAlertTextFieldTypeSecureText  = UIAlertViewStyleSecureTextInput,
    SLAlertTextFieldTypePlainText   = UIAlertViewStylePlainTextInput,
    SLAlertTextFieldTypeLogin       = UIAlertViewStyleLoginAndPasswordInput,
    SLAlertTextFieldTypePassword // = UIAlertViewStyleLoginAndPasswordInput
};


@class SLAlertHandler, SLAlertDismissHandler;

/**
 The `SLAlert` class allows access to, and control of, alerts within your application.

 Alerts do not need to be handled by the tests. If they are not handled,
 they will be automatically dismissed (by tapping the cancel button,
 if the button exists, then tapping the default button, if one is identifiable).

 A test may optionally specify an alternate handler for an alert, by constructing
 an `SLAlertHandler` from the `SLAlert` that matches that alert, and registering that
 handler with the `SLAlertHandler` class. When a matching alert appears, the handler
 dismisses the alert. The test then asks the handler to see if the alert was 
 dismissed as expected.
 
    SLAlert *alert = [SLAlert alertWithTitle:@"foo];

    // dismiss an alert with title "foo", when it appears
    SLAlertHandler *handler = [alert dismiss];
    [SLAlertHandler addHandler:handler];

    // test causes an alert with title "foo" to appear

    SLAssertTrueWithTimeout([handler didHandleAlert], SLAlertHandlerDidHandleAlertDelay, @"Alert did not appear.");

 @warning If a test wishes to manually handle an alert, it must register 
 a handler _before_ that alert appears.

 @warning If the alert has no cancel nor default button, it will not be able
 to be dismissed by any handler, and the tests will hang. (If the tests are being 
 run via the command line, Instruments will eventually time out; if the tests are 
 being run via the GUI, the developer will need to stop the tests.)

 */
@interface SLAlert : NSObject

#pragma mark - Matching Alerts
/// -----------------------------------
/// @name Matching Alerts
/// -----------------------------------

/**
 Creates and returns an alert object that matches an alert view 
 with the specified title.

 @param title The title of the alert.
 @return A newly created alert object.
 */
+ (instancetype)alertWithTitle:(NSString *)title;

#pragma mark - Handling Alerts
/// -----------------------------------
/// @name Handling Alerts
/// -----------------------------------

/**
 Creates and returns a handler that dismisses a matching alert using the default
 handling behavior.
 
 Which is to tap the cancel button, if the button exists, else tapping the 
 default button, if one is identifiable.
 
 @warning If the alert has no cancel nor default button, it will not be able
 to be dismissed and the tests will hang. (If the tests are being run via the command
 line, Instruments will eventually time out; if the tests are being run via the
 GUI, the developer can abort.)

 @return A newly created handler that dismisses the corresponding alert using 
 UIAutomation's default procedure.
 */
- (SLAlertDismissHandler *)dismiss;

/**
 Creates and returns a handler that dismisses a matching alert
 by tapping the button with the specified title.

 @param buttonTitle The title of the button to tap to dismiss the alert.
 @return A newly created handler that dismisses the corresponding alert by tapping 
 the button with the specified title.
 */
- (SLAlertDismissHandler *)dismissWithButtonTitled:(NSString *)buttonTitle;

/**
 Creates and returns a handler that sets the text of the specified text field 
 of a matching alert to a specified value.
 
 @param fieldType The type of text field, corresponding to the alert's 
 presentation style.
 @param text The text to enter into the field.
 @return A newly created handler that sets the text of the specified text field 
 of a matching alert to a `text`.
 */
- (SLAlertHandler *)setText:(NSString *)text ofFieldOfType:(SLAlertTextFieldType)fieldType;

@end


/**
 The "dismiss" methods of `SLAlert` vend instances of `SLAlertHandler` 
 that can dismiss corresponding alerts when they appear, 
 and report the status of dismissal to the tests.
 */
@interface SLAlertHandler : NSObject

#pragma mark - Adding and Removing Handlers
/// ------------------------------------------------
/// @name Adding and Removing Handlers
/// ------------------------------------------------

/**
 Allows tests to manually handle particular alerts.

 Tests can add multiple handlers at one time; when an alert is shown,
 they are checked in order of addition, and the first one that 
 [matches the alert](-[SLAlert isEqualToUIAAlertPredicate]) is given the chance 
 to handle (dismiss) the alert. If the handler succeeds, it is removed; otherwise, 
 the remaining handlers are checked.

 If an alert is not handled by any handler, it will be automatically dismissed
 by tapping the cancel button, if the button exists, then tapping the default button,
 if one is identifiable. If the alert is still not dismissed, the tests will hang.
 
 Each handler must be added only once.

 @warning Handlers must be added _before_ the alerts they handle might appear.
 
 @param handler An alert handler.
 
 @exception NSInternalInconsistencyException Thrown if a handler is added multiple times.
 @exception NSInternalInconsistencyException Thrown if the handler will not ultimately
 try to dismiss a corresponding alert: `handler` must either be an `SLAlertDismissHandler`,
 or must be a handler produced using `-andThen:` where the last "chained" handler
 is an `SLAlertDismissHandler`.
 */
+ (void)addHandler:(SLAlertHandler *)handler;

/**
 Removes the specified handler from the queue of `SLAlertHandlers` given a 
 chance to handle (dismiss) an alert when it is shown.
 
 @param handler An alert handler to remove.
 
 @exception NSInternalInconsistencyException Thrown if `handler` has not yet 
 been added.
 */
+ (void)removeHandler:(SLAlertHandler *)handler;

#pragma mark - Checking Dismissal Status
/// ------------------------------------------------
/// @name Checking Dismissal Status
/// ------------------------------------------------

/**
 Returns YES if the receiver has dismissed an alert, NO otherwise.
 
 Tests should assert that this is true within a timeout of `SLAlertHandlerDidHandleAlertDelay`.

 @return YES if the receiver has dismissed an alert, NO otherwise.
 
 @exception NSInternalInconsistencyException Thrown if the receiver has not been added.

 @see +addHandler:
 */
- (BOOL)didHandleAlert;

#pragma mark - Chaining Handlers
/// -------------------------------------
/// @name Chaining Handlers
/// -------------------------------------

/**
 Creates and returns an alert handler which handles a corresponding alert 
 by performing the action of the receiver and then that of the specified handler.
 
 This method allows alert handlers to be "chained", so that (for instance) 
 text can be entered into an alert's text field, and then the alert dismissed:
 
     SLAlert *alert = [SLAlert alertWithTitle:alertTitle];
 
     SLAlertHandler *setUsername = [alert setText:@"user" ofFieldOfType:SLAlertTextFieldTypeLogin];
     SLAlertHandler *setPassword = [alert setText:@"password" ofFieldOfType:SLAlertTextFieldTypePassword];
     SLAlertHandler *dismiss = [alert dismissWithButtonTitled:@"Ok"];
     SLAlertHandler *alertHandler = [[setUsername andThen:setPassword] andThen:dismiss];
 
     [SLAlertHandler addHandler:alertHandler];

 @param nextHandler A handler whose action should be performed after the action 
 of the receiver.
 @return A newly created alert handler that performs the action of the receiver 
 and then the action of _nextHandler_.
 */
- (SLAlertHandler *)andThen:(SLAlertHandler *)nextHandler;

@end


#pragma mark - Constants

/**
 The maximum amount of time it should take for an alert to be fully dismissed
 by a manual or automatic alert handler (including the alert's dismissal animation,
 and the alert's delegate receiving the `-alertView:didDismissWithButtonIndex:` callback),
 as measured from the time the alert appears.

 This timeout should suffice to dismiss alerts of all alert view styles
 (using handlers which simply dismiss the alerts, as well as those that enter text).
 
 If using a manual handler, you need not wait for this entire time:
 
    SLAssertTrueWithTimeout([handler didHandleAlert], SLAlertHandlerDidHandleAlertDelay, ...)

 If relying on automatic handling, your test should call
 `[self wait:SLAlertHandlerDidHandleAlertDelay]` (because you have no handler to check).
 */
extern const NSTimeInterval SLAlertHandlerDidHandleAlertDelay;


/**
 The methods in the `SLAlert (Subclassing)` category are to be used only by
 subclasses of `SLAlert`.
 */
@interface SLAlert (Subclassing)

#pragma mark - Methods for Subclasses
/// -------------------------------------------
/// @name Methods for Subclasses
/// -------------------------------------------

/**
 Returns the body of a JS function which
 evaluates a `UIAAlert` to see if it matches the receiver.

 The JS function will take one argument, "`alert`" (a `UIAAlert`), as argument,
 and should return true if `alert` is equivalent to the receiver, false otherwise.
 This method should return the _body_ of that function: one or more statements,
 with no function closure.

 The default implementation simply compares the titles of the receiving `SLAlert`
 and provided `UIAAlert`.

 @return The body of a JS function which evaluates a UIAAlert "`alert`"
 to see if it matches a particular `SLAlert`.
 */
- (NSString *)isEqualToUIAAlertPredicate;

@end


#if DEBUG

/**
 The methods in the `SLAlert (Debugging)` category are to be used only to 
 debug Subliminal tests.
 */
@interface SLAlert (Debugging)

#pragma mark - Debugging Tests

/// -------------------------------------------
/// @name Debugging Tests
/// -------------------------------------------

/**
 Creates and returns a handler that relies on a user to dismiss an alert.

 @warning Subliminal will _not_ dismiss an alert handled by this handler.
 This handler thus has a use only when debugging tests.

 @return A newly created handler that does not dismiss the corresponding alert, 
 but rather relies on a live user to dismiss the alert.
 */
- (SLAlertDismissHandler *)dismissByUser;

@end

#endif

/**
 The methods in the `SLAlertHandler (Debugging)` category may be useful 
 in debugging Subliminal tests.
 */
@interface SLAlertHandler (Debugging)

#pragma mark - Debugging Tests
/// ------------------------------------------
/// @name Debugging Tests
/// ------------------------------------------

/**
 Enables or disables alert-handling logging.
 
 If logging is enabled, Subliminal will log alerts as they are handled
 (by handlers registered by tests or by Subliminal's default handler).
 
 Logging is disabled by default.
 
 @param enableLogging   If `YES`, alert-handling logging is enabled; 
 otherwise, alert-handling logging is disabled.
 */
+ (void)setLoggingEnabled:(BOOL)enableLogging;

/**
 Returns `YES` if Subliminal should log alerts as they are handled.

 Logging is disabled by default.

 @return `YES` if alert-handling logging is enabled, `NO` otherwise.

 @see -setLoggingEnabled:
 */
+ (BOOL)loggingEnabled;

@end


/**
 `SLAlertDismissHandler` is a class used solely to distinguish handlers
 that try to dismiss alerts from those that do not.
 
 @see `+[SLAlertHandler addHandler:]`
 */
@interface SLAlertDismissHandler : SLAlertHandler
@end


/**
 The methods in the `SLAlertHandler (Internal)` category are to be used 
 only within Subliminal.
 */
@interface SLAlertHandler (Internal)

#pragma mark - Internal Methods
/// -------------------------------------------
/// @name Internal Methods
/// -------------------------------------------

/**
 Loads Subliminal's alert-handling mechanism into UIAutomation.
 
 `SLAlertHandler` is not fully functional until this method is called.
 
 This method is to be called by the test controller on startup.
 */
+ (void)loadUIAAlertHandling;

@end
