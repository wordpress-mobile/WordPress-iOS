//
//  SLTerminal.h
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
 The singleton `SLTerminal` instance communicates with the Automation instrument 
 in order to evaluate arbitrary JavaScript, in particular scripts which 
 call APIs defined by the UIAutomation JavaScript framework.
 */
@interface SLTerminal : NSObject

#pragma mark - Getting the Shared Terminal
/// ----------------------------------------
/// @name Getting the Shared Terminal
/// ----------------------------------------

/**
 Returns the terminal.
 
 @return The shared `SLTerminal` instance.
 */
+ (SLTerminal *)sharedTerminal;

#pragma mark - Evaluating JavaScript
/// ----------------------------------------
/// @name Evaluating JavaScript
/// ----------------------------------------

/**
 Evaluates the specified JavaScript script within UIAutomation and returns the 
 result as an Objective-C object.

 The evaluation is done using `eval()`.
 
 This method blocks until the script has been evaluated, and so must not be called 
 from the main thread.

 @param script The script to evaluate. May be a JavaScript expression, statement, 
 or sequence of statements. This value must not be `nil`.
 @return The value of the last expression evaluated, as an Objective-C object:
 
 - If the value is of type `"string"`, `-eval:` will return an `NSString *` 
 that is equal to the value.
 - If the value is of type `"boolean"`, `-eval:` will return an `NSNumber *` whose
 `-boolValue` is equal to the value.
 - If the value is of type `"number"`, `-eval:` will return an `NSNumber *` whose
 primitive value (using an accessor appropriate to the value's format) is equal 
 to the value.
 - Otherwise, `-eval:` will return `nil`.

 @exception NSInvalidArgumentException Thrown if `script` is `nil`.
 @exception NSInternalInconsistencyException Thrown if this method is called 
 from the main thread.
 @exception SLTerminalJavaScriptException Thrown if the script could not be 
 evaluated, or if the script threw an exception when evaluated.
 */
- (id)eval:(NSString *)script;

/**
 Evaluates the specified JavaScript script after substituting the specified argument
 variables into the script.
 
 This method is a wrapper around `eval:`: see that method for further discussion.
 
 @warning Variable arguments that are strings need to be escaped,
 using `-[NSString slStringByEscapingForJavaScriptLiteral]`,
 if they are to be substituted into a JavaScript string literal.

 @param script A format string (in the manner of `-[NSString stringWithFormat:]`) 
 to be evaluated as JavaScript after formatting. This value must not be `nil`.
 @param ... (Optional) A comma-separated list of arguments to substitute into `script`.
 @return The value of the last expression evaluated, as an Objective-C object. 
 See `-eval:` for more information.
 
 @exception NSInvalidArgumentException Thrown if `script` is `nil`.
 @exception NSInternalInconsistencyException Thrown if this method is called
 from the main thread.
 @exception SLTerminalJavaScriptException Thrown if the script could not be
 evaluated, or if the script threw an exception when evaluated.
 */
- (id)evalWithFormat:(NSString *)script, ... NS_FORMAT_FUNCTION(1, 2);

@end


/**
 The methods in the `SLTerminal (DebugSettings)` category may be useful 
 in debugging Subliminal. They may not be of much use in debugging
 tests because tests don't use the terminal directly.
 */
@interface SLTerminal (DebugSettings)

#pragma mark - Debugging Subliminal
/// -------------------------------------------
/// @name Debugging Subliminal
/// -------------------------------------------

/**
 Determines whether the terminal will log scripts as it evaluates them.
 
 If YES, the terminal will log each script before evaluating it.
 This allows developers to understand exactly what UIAutomation is doing 
 when a given Subliminal API is invoked.
 */
@property (nonatomic) BOOL scriptLoggingEnabled;

@end


/**
 The methods in the `SLTerminal (Internal)` category are to be used
 only within Subliminal.
 */
@interface SLTerminal (Internal)

#pragma mark - Internal Methods
/// ----------------------------------------
/// @name Internal Methods
/// ----------------------------------------

/** The namespace (in `SLTerminal.js`) in which the `SLTerminal` defines variables. */
@property (nonatomic, readonly) NSString *scriptNamespace;

/** The serial queue on which the receiver evaluates all JavaScript. */
@property (nonatomic, readonly) dispatch_queue_t evalQueue;

/**
 Whether or not the current queue is the `evalQueue`.
 
 To avoid deadlocks, use this method to check if you're on the `evalQueue` before `dispatch_sync`ing a block to it.
 
 @return Whether or not the current queue is the `evalQueue`.
 */
- (BOOL)currentQueueIsEvalQueue;

/**
 Causes `SLTerminal.js` to finish evaluating commands.

 The terminal starts up automatically when the UIAutomation instrument is attached
 and evaluating `SLTerminal.js`. `SLTerminal.js` then evaluates commands (scripts)
 sent through this terminal until this method is called, at which point
 `SLTerminal.js` will exit, and UIAutomation will terminate the application.

 This method is called by the shared test controller when testing has finished.
 */
- (void)shutDown;

@end


#pragma mark - Constants

/// Thrown if a JavaScript script could not be [evaluated](-eval:), or if the
/// script threw an exception when evaluated. The exception's reason will be the
/// string representation of the JavaScript `Exception` object.
extern NSString *const SLTerminalJavaScriptException;

/// `SLTerminal` waits for this duration between checking to see if a script
/// has finished evaluating.
extern const NSTimeInterval SLTerminalReadRetryDelay;

/// This interval represents an upper bound on the execution of a JavaScript
/// statement. It allows Subliminal's integration tests to calibrate timeouts.
extern const NSTimeInterval SLTerminalEvaluationDelay;
