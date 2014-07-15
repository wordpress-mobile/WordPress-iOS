//
//  SLTerminal+ConvenienceFunctions.h
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

#import "SLTerminal.h"

/**
 The `SLTerminal (ConvenienceFunctions)` category defines APIs that structure
 the definition and evaluation of JavaScript functions.

 It is oftentimes more readable and efficient to evaluate some bit of JavaScript
 by defining a generic function and then calling it with specific arguments, 
 rather than formatting and evaluating a long block of statements each time.
 */
@interface SLTerminal (ConvenienceFunctions)

#pragma mark - Evaluating Functions
/// ----------------------------------------
/// @name Evaluating Functions
/// ----------------------------------------

/**
 Adds the JavaScript function with the specified description to the terminal's 
 namespace.

 This method provides an idempotent, structured API for defining new functions.
 
 A function like

    function SLAddTwoNumbers(one, two) {
        return one + two;
    }
 
 would be added by calling this method as follows:
 
    [[SLTerminal sharedTerminal] loadFunctionWithName:@"SLAddTwoNumbers"
                                               params:@[ @"one", @"two" ]
                                                 body:@"return one + two;"];

 Developers should prefix their functions' names to avoid collisions with 
 functions defined by Subliminal. Subliminal reserves the "SL" prefix.

 @param name The name of the function.
 @param params The string names of the parameters of the function.
 @param body The body of the function: one or more statements, with no function 
 closure.
 
 @exception NSInternalInconsistencyException Thrown if a function with the 
 specified description has previously been loaded with different parameters 
 and/or body.
 @exception SLTerminalJavascriptException Thrown if the function name, params, 
 or body cannot be evaluated.
 
 @see -evalFunctionWithName:withArgs:
 @see -evalFunctionWithName:params:body:withArgs:
 */
- (void)loadFunctionWithName:(NSString *)name params:(NSArray *)params body:(NSString *)body;

/**
 Evaluates a JavaScript function existing in the terminal's namespace
 with the given arguments and returns the result, if any.
 
 A function like
 
    function SLAddTwoNumbers(one, two) {
        return one + two;
    }

 would be evaluated with the arguments `5, 7` by calling this method as follows:
 
    NSString *result = [[SLTerminal sharedTerminal] evalFunctionWithName:@"SLAddTwoNumbers"
                                                                withArgs:@[ @"5", @"7" ]];
 
 After evaluation, `result` would contain `@"12"`.

 @param name The name of a function previously added to the terminal's namespace.
 @param args The arguments to the function, as strings.
 @return The result of evaluating the specified function, or `nil` if the function 
 does not return a value.

 @exception NSInternalInconsistencyException Thrown if a function with the 
 specified name has not previously been loaded.
 @exception SLTerminalJavascriptException Thrown if an exception occurs when 
 evaluating the function.
 
 @see -loadFunctionWithName:params:body:
 @see -evalFunctionWithName:params:body:withArgs:
 */
- (NSString *)evalFunctionWithName:(NSString *)name withArgs:(NSArray *)args;

/**
 Adds the JavaScript function with the specified description to the terminal's
 namespace, if necessary; evaluates it with the given arguments; and returns 
 the result, if any.
 
 This is a convenience wrapper for the other methods in this section.
 An invocation of this method like

    NSString *result = [[SLTerminal sharedTerminal] evalFunctionWithName:@"SLAddTwoNumbers"
                                                                  params:@[ @"one", @"two" ]
                                                                    body:@"return one + two;"];
                                                                withArgs:@[ @"5", @"7" ]];
 
 is equivalent to calling
 
    [[SLTerminal sharedTerminal] loadFunctionWithName:@"SLAddTwoNumbers"
                                               params:@[ @"one", @"two" ]
                                                 body:@"return one + two;"];
    NSString *result = [[SLTerminal sharedTerminal] evalFunctionWithName:@"SLAddTwoNumbers"
                                                                withArgs:@[ @"5", @"7" ]];

 @param name The name of the function to add to the terminal's namespace, if necessary.
 @param params The string names of the parameters of the function.
 @param body The body of the function: one or more statements, with no function closure.
 @param args The arguments to the function, as strings.
 @return The result of evaluating the specified function, or `nil` if the function
 does not return a value.

 @exception NSInternalInconsistencyException Thrown if a function with the 
 specified description has previously been loaded with different parameters 
 and/or body.
 @exception SLTerminalJavascriptException Thrown if the function name, params, 
 or body cannot be evaluated when the function is added to the terminal's namespace, 
 or if an exception occurs when evaluating the function.
 
 @see -loadFunctionWithName:params:body:
 @see -evalFunctionWithName:withArgs:
 */
- (NSString *)evalFunctionWithName:(NSString *)name
                            params:(NSArray *)params
                              body:(NSString *)body
                          withArgs:(NSArray *)args;

#pragma mark - Waiting on Boolean Expressions and Functions
/// -----------------------------------------------------------
/// @name Waiting on Boolean Expressions and Functions
/// -----------------------------------------------------------

/**
 Waits for an arbitrary JavaScript expression to evaluate to true
 within a specified timeout.

 This method is designed to wait efficiently by performing the waiting/re-evaluation
 entirely within UIAutomation's (JavaScript) context.

 The expression will be re-evaluated at small intervals.
 If and when the expression evaluates to true, the method will immediately return
 `YES`; if the expression is still false at the end of the timeout, this method
 will return `NO`.

 @warning This method does not itself throw an exception if the condition fails
 to become true within the timeout. Rather, the caller should throw a suitably
 specific exception if this method returns `NO`.

 @param condition A boolean expression in JavaScript, on whose truth the method 
 should wait.
 @param retryDelay The interval at which to re-evaluate condition.
 @param timeout The interval for which to wait.
 @return `YES` if and when the expression evaluates to true within the timeout;
 otherwise, `NO`.
 
 @exception SLTerminalJavascriptException Thrown if condition cannot be evaluated.
 
 @see -waitUntilFunctionWithNameIsTrue:whenEvaluatedWithArgs:retryDelay:timeout:
 */
- (BOOL)waitUntilTrue:(NSString *)condition
           retryDelay:(NSTimeInterval)retryDelay
              timeout:(NSTimeInterval)timeout;

/**
 Waits for a JavaScript function existing in the terminal's namespace 
 to evaluate to true, given the specified arguments, within a specified timeout.
 
 This is a wrapper around `-waitUntilTrue:retryDelay:timeout:` where `condition`
 is a call to the specified function with the given arguments.
 
 @param name The name of a function previously added to the terminal's namespace.
 @param args The arguments to the function, as strings.
 @param retryDelay The interval at which to re-evaluate the function.
 @param timeout The interval for which to wait.
 @return `YES` if and when the function evaluates to true within the timeout;
 otherwise, `NO`.
 
 @exception NSInternalInconsistencyException Thrown if a function with the 
 specified name has not previously been loaded.
 @exception SLTerminalJavascriptException Thrown if an exception occurs when 
 evaluating the function.
 */
- (BOOL)waitUntilFunctionWithNameIsTrue:(NSString *)name
                  whenEvaluatedWithArgs:(NSArray *)args
                             retryDelay:(NSTimeInterval)retryDelay
                                timeout:(NSTimeInterval)timeout;

@end
