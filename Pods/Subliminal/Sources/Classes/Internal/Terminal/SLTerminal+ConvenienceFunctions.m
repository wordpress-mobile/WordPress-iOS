//
//  SLTerminal+ConvenienceFunctions.m
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

#import "SLTerminal+ConvenienceFunctions.h"

#import <objc/runtime.h>


@interface SLTerminal (ConvenienceFunctions_Internal)

/**
 Returns a Boolean value that indicates whether a function with the specified
 name has been added to Subliminal's namespace.
 
 @param name The name of a function.
 @return YES if a function with the specified name has previously been added 
 to Subliminal's namespace, NO otherwise.
 */
- (BOOL)functionWithNameIsLoaded:(NSString *)name;

@end


@implementation SLTerminal (ConvenienceFunctions)

#pragma mark - Evaluating functions

/// All access to this dictionary, and addition of functions to Subliminal's
/// namespace, should be done on the terminal's evalQueue for thread safety.
- (NSMutableDictionary *)loadedFunctions {
    static const void *const kFunctionsLoadedKey = &kFunctionsLoadedKey;
    NSMutableDictionary *functionsLoaded = objc_getAssociatedObject(self, kFunctionsLoadedKey);
    if (!functionsLoaded) {
        functionsLoaded = [[NSMutableDictionary alloc] init];
        objc_setAssociatedObject(self, kFunctionsLoadedKey, functionsLoaded, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return functionsLoaded;
}

- (BOOL)functionWithNameIsLoaded:(NSString *)name {
    if (![self currentQueueIsEvalQueue]) {
        __block BOOL functionIsLoaded;
        dispatch_sync(self.evalQueue, ^{
            functionIsLoaded = [self functionWithNameIsLoaded:name];
        });
        return functionIsLoaded;
    }
    
    return ([self loadedFunctions][name] != nil);
}

- (void)loadFunctionWithName:(NSString *)name params:(NSArray *)params body:(NSString *)body {
    if (![self currentQueueIsEvalQueue]) {
        NSException *__block loadException;
        dispatch_sync(self.evalQueue, ^{
            @try {
                [self loadFunctionWithName:name params:params body:body];
            }
            @catch (NSException *exception) {
                loadException = exception;
            }
        });
        if (loadException) @throw loadException;
        return;
    }
    
    NSString *paramList = [params componentsJoinedByString:@", "];
    NSString *function = [NSString stringWithFormat:@"%@.%@ = function(%@){ %@ }", self.scriptNamespace, name, paramList, body];
    NSString *loadedFunction = [self loadedFunctions][name];
    if (!loadedFunction) {
        [self eval:function];
        [self loadedFunctions][name] = function;
    } else {
        NSAssert([function isEqualToString:loadedFunction],
                 @"Function with name %@, params %@, and body %@ has previously been loaded with different parameters and/or body: %@",
                 name, params, body, loadedFunction);
    }
}

- (NSString *)evalFunctionWithName:(NSString *)name withArgs:(NSArray *)args {
    if (![self currentQueueIsEvalQueue]) {
        NSString *__block result;
        NSException *__block evalException;
        dispatch_sync(self.evalQueue, ^{
            @try {
                result = [self evalFunctionWithName:name withArgs:args];
            }
            @catch (NSException *exception) {
                evalException = exception;
            }
        });
        if (evalException) @throw evalException;
        return result;
    }
    
    NSAssert([self functionWithNameIsLoaded:name], @"No function with name %@ has been loaded.", name);
    NSString *argList = [args componentsJoinedByString:@", "];
    return [self evalWithFormat:@"%@.%@(%@)", self.scriptNamespace, name, argList];
}

- (NSString *)evalFunctionWithName:(NSString *)name
                            params:(NSArray *)params
                              body:(NSString *)body
                          withArgs:(NSArray *)args {
    if (![self currentQueueIsEvalQueue]) {
        NSString *__block result;
        NSException *__block evalException;
        dispatch_sync(self.evalQueue, ^{
            @try {
                result = [self evalFunctionWithName:name params:params body:body withArgs:args];
            }
            @catch (NSException *exception) {
                evalException = exception;
            }
        });
        if (evalException) @throw evalException;
        return result;
    }
    
    [self loadFunctionWithName:name params:params body:body];
    return [self evalFunctionWithName:name withArgs:args];
}

#pragma mark - Waiting on boolean expressions and functions

- (BOOL)waitUntilTrue:(NSString *)condition
           retryDelay:(NSTimeInterval)retryDelay
              timeout:(NSTimeInterval)timeout {
    NSString *conditionFunction = [NSString stringWithFormat:@"function() { return (%@); }", condition];
    NSString *retryDelayStr = [NSString stringWithFormat:@"%g", retryDelay];
    NSString *timeoutStr = [NSString stringWithFormat:@"%g", timeout];
    return [[self evalFunctionWithName:@"SLAssertTrueWithTimeout"
                                params:@[ @"condition", @"retryDelay", @"timeout" ]
                                  body:@"var startTime = (Date.now() / 1000);\
                                         var condTrue = false;\
                                         while (!(condTrue = condition()) && (((Date.now() / 1000) - startTime) < timeout)) {\
                                             UIATarget.localTarget().delay(retryDelay);\
                                         };\
                                         return condTrue;"
                              withArgs:@[ conditionFunction, retryDelayStr, timeoutStr ]] boolValue];
}

- (BOOL)waitUntilFunctionWithNameIsTrue:(NSString *)name
                  whenEvaluatedWithArgs:(NSArray *)args
                             retryDelay:(NSTimeInterval)retryDelay
                                timeout:(NSTimeInterval)timeout {
    NSAssert([self functionWithNameIsLoaded:name], @"No function with name %@ has been loaded.", name);
    NSString *argList = [args componentsJoinedByString:@", "];
    NSString *condition = [NSString stringWithFormat:@"%@.%@(%@)", self.scriptNamespace, name, argList];
    return [self waitUntilTrue:condition retryDelay:retryDelay timeout:timeout];
}

@end
