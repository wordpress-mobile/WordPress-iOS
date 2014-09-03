//
//  SILoggingTerminal.m
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

#import "SILoggingTerminal.h"

#import <OCMock/OCMock.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <SLLogger/SLTerminal.h>

NSString *const SILoggingTerminalMessageLoggedNotification = @"SILoggingTerminalMessageLoggedNotification";
NSString *const SILoggingTerminalMessageUserInfoKey = @"SILoggingTerminalMessageUserInfoKey";

@implementation SILoggingTerminal {
    id _terminalMock;
    JSGlobalContextRef _loggingContext;
}

+ (void)initialize {
    // initialize the shared terminal, to prevent an `SILoggingTerminal`
    // from being manually initialized prior to `+sharedTerminal` being invoked,
    // bypassing the assert at the top of `-init`
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [SILoggingTerminal sharedTerminal];
#pragma clang diagnostic pop
}

static SILoggingTerminal *__sharedTerminal = nil;
+ (instancetype)sharedTerminal {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedTerminal = [[SILoggingTerminal alloc] init];
    });
    return __sharedTerminal;
}

- (id)init {
    NSAssert(!__sharedTerminal, @"`SILoggingTerminal` should not be initialized manually. Use `+sharedTerminal` instead.");

    self = [super init];
    if (self) {
        // Prepare our logging context (see `-eval:` for its use).
        _loggingContext = JSGlobalContextCreate(NULL);

        NSString *loggingScriptPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"SILoggingTerminal" ofType:@"js"];
        NSAssert([loggingScriptPath length], @"`SILoggingTerminal.js` was not found.");

        NSString *loggingScript = [NSString stringWithContentsOfFile:loggingScriptPath encoding:NSUTF8StringEncoding error:NULL];
        JSStringRef jsLoggingScript = JSStringCreateWithUTF8CString([loggingScript UTF8String]);
        NSAssert(jsLoggingScript, @"JS script was not successfully created.");

        NSAssert(JSEvaluateScript(_loggingContext, jsLoggingScript, NULL, NULL, 0, NULL),
                 @"Script threw an exception when evaluated.");
        JSStringRelease(jsLoggingScript);
    }
    return self;
}

- (void)dealloc {
    if (_loggingContext) JSGlobalContextRelease(_loggingContext);
}

- (void)beginMocking {
    _terminalMock = [OCMockObject partialMockForObject:[SLTerminal sharedTerminal]];

    // this causes a retain loop but that's ok because we're a singleton anyway
    (void)[[[_terminalMock stub] andCall:@selector(eval:) onObject:self] eval:OCMOCK_ANY];
}

- (void)stopMocking {
    [_terminalMock stopMocking];
    _terminalMock = nil;
}

#pragma mark - Evaluation

// This method is called when the real `SLTerminal` is asked to evaluate a script,
// i.e. when `SLLogger` tries to log a message to UIAutomation.
// We evaluate the message in our own context, using a simplified version of
// UIAutomation's logger, and make it available to our client.
- (id)eval:(NSString *)script {
    NSParameterAssert(script);

    JSStringRef jsScript = JSStringCreateWithUTF8CString([script UTF8String]);
    NSAssert(jsScript, @"JS script was not successfully created.");

    JSValueRef jsResult = JSEvaluateScript(_loggingContext, jsScript, NULL, NULL, 0, NULL);
    JSStringRelease(jsScript);
    NSAssert(jsResult, @"\"%@\" threw an exception when evaluated.", script);

    JSStringRef jsResultString = JSValueToStringCopy(_loggingContext, jsResult, NULL);
    NSAssert(jsResultString, @"Could not convert the result of evaluating \"%@\" to a string.", script);

    NSString *message = CFBridgingRelease(JSStringCopyCFString(kCFAllocatorDefault, jsResultString));
    JSStringRelease(jsResultString);
    NSAssert([message length], @"Either a `nil` message was logged, or our script returned `nil`.");

    NSDictionary *messageLoggedInfo = @{
        SILoggingTerminalMessageUserInfoKey: message
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:SILoggingTerminalMessageLoggedNotification
                                                        object:self
                                                      userInfo:messageLoggedInfo];

    // `-[SLTerminal eval:]` is expected to return the result of evaluation.
    // UIAutomation's logging functions return `undefined`, so we return `nil`.
    return nil;
}

@end
