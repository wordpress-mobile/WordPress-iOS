//
//  SLAlert.m
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

#import "SLAlert.h"
#import "SLTerminal.h"
#import "SLTerminal+ConvenienceFunctions.h"
#import "SLStringUtilities.h"

const NSTimeInterval SLAlertHandlerDidHandleAlertDelay = 2.0;

/**
 SLAlertHandlerDidHandleAlertDelay represents the maximum amount of time that 
 an alert might take to be dismissed.
 
 Because alerts may be dismissed much quicker than that, though, 
 manual handlers must wait for `SLAlertHandlerManualDelay` before returning, 
 so that their alert's delegate receives its callbacks before the tests
 continue, assuming that the tests are waiting-with-timeout on `didHandleAlert`. 
 */
static const NSTimeInterval SLAlertHandlerManualDelay = 1.0;


#pragma mark - SLAlertHandler

// SLAlertDismissHandler has behavior identical to SLAlertHandler
// --we just use the class to distinguish certain handlers from others
@implementation SLAlertDismissHandler
@end


/**
 SLAlertMultiHandler is an alert handler which handles a corresponding alert 
 by performing the actions of a series of component handlers in succession.
 */
@interface SLAlertMultiHandler : SLAlertHandler

/** The handlers whose actions the receiver will perform, in order. */
@property (nonatomic, readonly) NSArray *handlers;

/**
 Initializes and returns a newly allocated multi-handler for the specified alert.
 
 @param alert The alert to handle.
 @param handlers The array of handlers whose actions to perform, in order, 
 to handle alert.
 @return An initialized multi-handler.
 
 @exception NSInternalInconsistencyException if any of handlers do not handle 
 alert.
 */
- (instancetype)initWithSLAlert:(SLAlert *)alert handlers:(NSArray *)handlers;

@end


@interface SLAlertHandler ()

/**
 Returns a value unique to this handler, for use in identifying
 it among the handlers registered.

 @return A value that uniquely identifies this handler.
 */
@property (nonatomic, readonly) NSString *identifier;

/**
 Returns a UIAAlert handler modeled after UIAutomation's default onAlert handler.

 @return A UIAAlert handler (suitable to initialize an SLAlertHandler) 
 which taps the alert's cancel button, if the button exists, else taps the 
 default button, if one is identifiable.
 */
+ (NSString *)defaultUIAAlertHandler;

/**
 Initializes and returns a newly allocated handler for the specified alert.
 
 @param alert The alert to handle.
 @param UIAAlertHandler The logic to execute to handle alert. This should be the 
 body of a JS function--one or more statements, with no function closure--taking 
 one argument, "alert" (a UIAAlert) as argument, and returning true if the alert 
 was successfully dismissed, false otherwise.
 @return An initialized handler.
 */
- (instancetype)initWithSLAlert:(SLAlert *)alert
             andUIAAlertHandler:(NSString *)UIAAlertHandler;

@end

@implementation SLAlertHandler {
    @protected
    SLAlert *_alert;
    NSString *_UIAAlertHandler;

    @private
    BOOL _hasBeenAdded;
}

static BOOL SLAlertHandlerUIAAlertHandlingLoaded = NO;
static BOOL SLAlertHandlerLoggingEnabled = NO;
+ (void)loadUIAAlertHandling {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // The onAlert handler returns true for an alert
        // iff Subliminal handles and dismisses that alert.
        // SLAlertHandler manipulates onAlert via `SLAlertHandler.alertHandlers` and `SLAlertHandler.loggingEnabled`.
        [[SLTerminal sharedTerminal] evalWithFormat:@"\
            var SLAlertHandler = {};\
            SLAlertHandler.previousOnAlert = UIATarget.onAlert;\
            SLAlertHandler.alertHandlers = [];\
            SLAlertHandler.loggingEnabled = %@;"

            @"UIATarget.onAlert = function(alert) {\
                if (SLAlertHandler.loggingEnabled) UIALogger.logMessage('Handling alert \"' + alert.name() + '\"…');"
         
                // enumerate registered handlers, from first to last
                @"for (var handlerIndex = 0; handlerIndex < SLAlertHandler.alertHandlers.length; handlerIndex++) {\
                    var handler = SLAlertHandler.alertHandlers[handlerIndex];"
                    // if a handler matches the alert...
                    @"if (handler.handleAlert(alert) === true) {\
                        if (SLAlertHandler.loggingEnabled) UIALogger.logMessage('Alert was handled by a test.');"
                        // ...ensure that the alert's delegate will receive its callbacks
                        // before the next JS command (i.e. -didHandleAlert) evaluates...
                        @"UIATarget.localTarget().delay(%g);"
                        // ...then remove the handler and return true
                        @"SLAlertHandler.alertHandlers.splice(handlerIndex, 1);\
                        return true;\
                    }\
                }"
                
                // The tests haven't handled this alert, so we should attempt to
                // dismiss it using the default handler. We invoke our default handler
                // before UIAutomation's, though it has the same behavior,
                // because in the event that the alert cannot be dismissed
                // we want to log a message--UIAutomation's handler is supposed
                // to throw an error, but doesn't; instead, it will just keep retrying.
                @"if ((function(alert){%@})(alert)) {\
                        if (SLAlertHandler.loggingEnabled) UIALogger.logMessage('Alert was handled by Subliminal\\'s default handler.');\
                        return true;\
                  } else {"
                      // All we can do is log a message--if we throw an exception, Instruments will crash >.<
                      // We always log this error (not respecting `SLAlertHandler.loggingEnabled`) because it's fatal.
                      @"UIALogger.logError('Alert was not handled by a test, and could not be dismissed by Subliminal\\'s default handler.');"
                      // Reset the onAlert handler so our handler doesn't get called infinitely
                      @"UIATarget.onAlert = SLAlertHandler.previousOnAlert;"
                      // If our default handler was unable to dismiss this alert,
                      // it's unlikely that UIAutomation's will be able to either,
                      // but we might as well invoke it.
                      @"return false;\
                  }\
            }\
         ", SLAlertHandlerLoggingEnabled ? @"true" : @"false", SLAlertHandlerManualDelay, [self defaultUIAAlertHandler]];
        SLAlertHandlerUIAAlertHandlingLoaded = YES;
    });
}

+ (void)setLoggingEnabled:(BOOL)enableLogging {
    if (enableLogging != SLAlertHandlerLoggingEnabled) {
        SLAlertHandlerLoggingEnabled = enableLogging;
        if (SLAlertHandlerUIAAlertHandlingLoaded) {
            [[SLTerminal sharedTerminal] evalWithFormat:@"SLAlertHandler.loggingEnabled = %@",
                                                        SLAlertHandlerLoggingEnabled ? @"true" : @"false"];
        }
    }
}

+ (BOOL)loggingEnabled {
    return SLAlertHandlerLoggingEnabled;
}

+ (void)addHandler:(SLAlertHandler *)handler {
    // We don't use NSParameterAsserts here because if they failed
    // they'd leak the implementation (in the form of their conditions) to the client
    if (handler->_hasBeenAdded) {
        [NSException raise:NSInternalInconsistencyException format:@"Handler for alert %@ must not be added twice.", handler->_alert];
    }
    SLAlertHandler *lastHandler = handler;
    while ([lastHandler isKindOfClass:[SLAlertMultiHandler class]]) {
        lastHandler = [((SLAlertMultiHandler *)handler).handlers lastObject];
    }
    if (![lastHandler isKindOfClass:[SLAlertDismissHandler class]]) {
        [NSException raise:NSInternalInconsistencyException format:@"Handler for alert %@ must dismiss alert.", handler->_alert];
    }

    NSString *alertHandler = [NSString stringWithFormat:@"{\
                                  id: \"%@\",\
                                  handleAlert: function(alert){ %@ }\
                              }",
                              [[handler identifier] slStringByEscapingForJavaScriptLiteral], [handler JSHandler]];
    [[SLTerminal sharedTerminal] evalWithFormat:@"SLAlertHandler.alertHandlers.push(%@);", alertHandler];
    handler->_hasBeenAdded = YES;
}

+ (void)removeHandler:(SLAlertHandler *)handler {
    // We don't use NSParameterAsserts here because if they failed
    // they'd leak the implementation (in the form of their conditions) to the client
    if (!handler->_hasBeenAdded) {
        [NSException raise:NSInternalInconsistencyException format:@"Handler for alert %@ must have been added before being removed.", handler->_alert];
    }
    
    NSString *alertHandlerId = [[handler identifier] slStringByEscapingForJavaScriptLiteral];
    [[SLTerminal sharedTerminal] evalWithFormat:@"\
        for (var handlerIndex = 0; handlerIndex < SLAlertHandler.alertHandlers.length; handlerIndex++) {\
            var handler = SLAlertHandler.alertHandlers[handlerIndex];\
            if (handler.id === \"%@\") {\
                SLAlertHandler.alertHandlers.splice(handlerIndex,1);\
                break;\
            }\
        }", alertHandlerId];

    handler->_hasBeenAdded = NO;
}

+ (NSString *)defaultUIAAlertHandler {
    static NSString *defaultUIAAlertHandler;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // in iOS 6 and below, a `UIAlertView`'s buttons are actually buttons.
        // in iOS 7, each "button" is really a single table view cell in its own table view.
        // On all platforms, the accessibility hierarchy is structured such that the cancel "button"
        // will be the first element of its kind, then the rest.
        // If there's no cancel "button" then the default "button" will be the first.
        NSString *firstButtonElement;
        if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_6_1) {
            firstButtonElement = @"alert.buttons()[0]";
        } else {
            firstButtonElement = @"alert.tableViews()[0].cells()[0]";
        }
        defaultUIAAlertHandler = [NSString stringWithFormat:@"\
            var didDismissAlert = false;\
            if (%@.isValid()) {\
                %@.tap();\
                didDismissAlert = true;\
            }\
            return didDismissAlert;\
        ", firstButtonElement, firstButtonElement];
    });
    return defaultUIAAlertHandler;
}

- (instancetype)initWithSLAlert:(SLAlert *)alert
             andUIAAlertHandler:(NSString *)UIAAlertHandler {
    self = [super init];
    if (self) {
        NSParameterAssert(alert);
        NSParameterAssert([UIAAlertHandler length]);

        _alert = alert;
        _UIAAlertHandler = UIAAlertHandler;
    }
    return self;
}

- (NSString *)identifier {
    return [NSString stringWithFormat:@"%p", self];
}

- (NSString *)JSHandler {
    return [NSString stringWithFormat:@"\
                var shouldHandleAlert = (function(alert){%@})(alert);\
                if (shouldHandleAlert) {\
                    return (function(alert){%@})(alert);\
                } else {\
                    return false;\
                }\
        ", [_alert isEqualToUIAAlertPredicate], _UIAAlertHandler];
}

- (BOOL)didHandleAlert {
    if (!_hasBeenAdded) {
        [NSException raise:NSInternalInconsistencyException format:@"Handler for alert %@ must be added using +[SLAlertHandler addHandler:] before it can handle an alert.", _alert];
    }

    static NSString *const SLAlertHandlerDidHandleAlertFunctionName = @"SLAlertHandlerDidHandleAlert";
    NSString *quotedIdentifier = [NSString stringWithFormat:@"'%@'", [self.identifier slStringByEscapingForJavaScriptLiteral]];
    return [[[SLTerminal sharedTerminal] evalFunctionWithName:SLAlertHandlerDidHandleAlertFunctionName
                                                       params:@[ @"alertId" ]
                                                         body:@""
                                                     // we've handled an alert unless we find ourselves still registered
                                                     @"var haveHandledAlert = true;"
                                                     // enumerate registered handlers, from first to last
                                                     @"for (var handlerIndex = 0; handlerIndex < SLAlertHandler.alertHandlers.length; handlerIndex++) {\
                                                         var handler = SLAlertHandler.alertHandlers[handlerIndex];\
                                                         if (handler.id === alertId) {\
                                                             haveHandledAlert = false;\
                                                             break;\
                                                         }\
                                                     };\
                                                     return haveHandledAlert;\
                                                     "
                                                     withArgs:@[ quotedIdentifier ]] boolValue];
}

- (SLAlertHandler *)andThen:(SLAlertHandler *)nextHandler {
    return [[SLAlertMultiHandler alloc] initWithSLAlert:_alert handlers:@[ self, nextHandler ]];
}

@end

@implementation SLAlertMultiHandler

- (instancetype)initWithSLAlert:(SLAlert *)alert handlers:(NSArray *)handlers {
    NSParameterAssert(alert);
    NSParameterAssert([handlers count]);
    
    NSMutableString *UIAAlertHandler = [NSMutableString stringWithString:@"return"];
    [handlers enumerateObjectsUsingBlock:^(SLAlertHandler *handler, NSUInteger idx, BOOL *stop) {
        NSParameterAssert(handler->_alert == alert);
        [UIAAlertHandler appendFormat:@" (function(alert){%@})(alert)", handler->_UIAAlertHandler];
        if (idx < ([handlers count] - 1)) {
            [UIAAlertHandler appendString:@" &&"];
        }
    }];
    [UIAAlertHandler appendString:@";"];

    self = [super initWithSLAlert:alert andUIAAlertHandler:UIAAlertHandler];
    if (self) {
        _handlers = [handlers copy];
    }
    return self;
}

@end


#pragma mark - SLAlert

@implementation SLAlert {
    NSString *_title;
}

+ (instancetype)alertWithTitle:(NSString *)title {
    NSParameterAssert([title length]);
    
    SLAlert *alert = [[SLAlert alloc] init];
    alert->_title = title;
    return alert;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ title:\"%@\">", NSStringFromClass([self class]), _title];
}

- (SLAlertDismissHandler *)dismiss {
    return [[SLAlertDismissHandler alloc] initWithSLAlert:self andUIAAlertHandler:[SLAlertHandler defaultUIAAlertHandler]];
}

- (SLAlertDismissHandler *)dismissWithButtonTitled:(NSString *)buttonTitle {
    static NSString *buttonElementWithTitleFunction;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // in iOS 6 and below, a `UIAlertView`'s buttons are actually buttons.
        // in iOS 7, each "button" is really a single table view cell in its own table view.
        BOOL isIOS6OrBelow = (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_6_1);
        buttonElementWithTitleFunction = [NSString stringWithFormat:@"\
            function (title) {\
                if (%@) {\
                    return alert.buttons()[title];\
                } else {\
                    for (var tableViewIndex = 0; tableViewIndex < alert.tableViews().length; tableViewIndex++) {\
                        var tableView = alert.tableViews()[tableViewIndex];\
                        var buttonCell = tableView.cells()[title];\
                        if (buttonCell.isValid()) return buttonCell;\
                    }"
                    // I'd really like to return `UIAElementNil` here but I don't know how to use it by itself
                    @"return null;\
                }\
            }", isIOS6OrBelow ? @"true" : @"false"];
    });
    NSString *UIAAlertHandler = [NSString stringWithFormat:@"\
                                     var buttonElement = (%@)('%@');\
                                     if (buttonElement && buttonElement.isValid()) {\
                                        buttonElement.tap();\
                                        return true;\
                                     } else {\
                                        return false;\
                                     }\
                                 ", buttonElementWithTitleFunction, [buttonTitle slStringByEscapingForJavaScriptLiteral]];
    return [[SLAlertDismissHandler alloc] initWithSLAlert:self andUIAAlertHandler:UIAAlertHandler];
}

- (SLAlertHandler *)setText:(NSString *)text ofFieldOfType:(SLAlertTextFieldType)fieldType {
    // in iOS 6 and below, a `UIAlertView`'s text fields are direct children of the alert
    // on iOS 7, the alert contains an image which then contains the text fields
    NSString *elementContainerExpression = @"alert";
    if (kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_6_1) {
        elementContainerExpression = [elementContainerExpression stringByAppendingString:@".images()[0]"];
    }
    NSString *elementType;
    switch (fieldType) {
        case SLAlertTextFieldTypeSecureText:
        case SLAlertTextFieldTypePassword:
            elementType = @"secureTextFields";
            break;
        case SLAlertTextFieldTypePlainText:
        case SLAlertTextFieldTypeLogin:
            elementType = @"textFields";
            break;
    }

    // even in the case when two fields, login and password, are displayed,
    // the password field is at index 0--because it is the only element of its type
    NSUInteger elementIndex = 0;

    NSString *UIAAlertHandler = [NSString stringWithFormat:@"\
                                    var textField = %@.%@()[%lu];\
                                    if (textField.isValid()) {\
                                        textField.setValue('%@');\
                                        return true;\
                                    } else {\
                                        return false;\
                                    }\
                                 ", elementContainerExpression, elementType, (unsigned long)elementIndex, [text slStringByEscapingForJavaScriptLiteral]];
    return [[SLAlertHandler alloc] initWithSLAlert:self andUIAAlertHandler:UIAAlertHandler];
}

- (NSString *)isEqualToUIAAlertPredicate {
    static NSString *const kIsEqualToUIAAlertPredicateFormatString = @"\
        return alert.name() === \"%@\";\
    ";
    NSString *isEqualToUIAAlertPredicate = [NSString stringWithFormat:kIsEqualToUIAAlertPredicateFormatString,
                                            [_title slStringByEscapingForJavaScriptLiteral]];
    return isEqualToUIAAlertPredicate;
}

@end


#if DEBUG

@implementation SLAlert (Debugging)

- (SLAlertDismissHandler *)dismissByUser {
    // Once we match an alert, we simply return true, suggesting that we did handle it.
    // SLAlertHandler will then direct UIAutomation to ignore the alert
    // --but without us tapping any buttons, the alert will remain visible,
    // until the user dismisses it.
    return [[SLAlertDismissHandler alloc] initWithSLAlert:self andUIAAlertHandler:@"return true;"];
}

@end

#endif
