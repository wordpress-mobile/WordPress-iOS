//
//  SLLogger.m
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

#import "SLLogger.h"

#import "SLLogger.h"
#import "SLTerminal.h"
#import "SLStringUtilities.h"


NSString *const SLLoggerExceptionFilenameKey      = @"SLLoggerExceptionFilenameKey";
NSString *const SLLoggerExceptionLineNumberKey    = @"SLLoggerExceptionLineNumberKey";

NSString *const SLLoggerUnknownCallSite           = @"Unknown location";

/**
 Identifier for the `loggingQueue` for use with `dispatch_get_specific`.
 */
static const void *const kLoggingQueueIdentifier = &kLoggingQueueIdentifier;


void SLLog(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    [[SLLogger sharedLogger] logMessage:[[NSString alloc] initWithFormat:format arguments:args]];
    va_end(args);
}

void SLLogAsync(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    dispatch_async([[SLLogger sharedLogger] loggingQueue], ^{
        [[SLLogger sharedLogger] logMessage:message];
    });
}

@implementation SLLogger {
    dispatch_queue_t _loggingQueue;
}

+ (SLLogger *)sharedLogger {
    static SLLogger *sharedLogger;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedLogger = [[SLLogger alloc] init];
    });
    return sharedLogger;
}

- (id)init {
    self = [super init];
    if (self) {
        _loggingQueue = dispatch_queue_create("com.inkling.subliminal.SLUIALogger.loggingQueue", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(_loggingQueue, kLoggingQueueIdentifier, (void *)kLoggingQueueIdentifier, NULL);
    }
    return self;
}

- (void)dealloc {
    // On OS X 10.8, dispatch objects are NSObjects, and ARC renders it unnecessary
    // (and impossible) to manually release objects.
    // But on iOS, dispatch objects only become NSObjects in iOS 6,
    // and Subliminal still supports 5.1.
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    dispatch_release(_loggingQueue);
#endif
}

- (dispatch_queue_t)loggingQueue {
    return _loggingQueue;
}

- (BOOL)currentQueueIsLoggingQueue
{
    return dispatch_get_specific(kLoggingQueueIdentifier) != NULL;
}

- (void)logDebug:(NSString *)debug {
    if (![self currentQueueIsLoggingQueue]) {
        dispatch_sync(_loggingQueue, ^{
            [self logDebug:debug];
        });
        return;
    }

    [[SLTerminal sharedTerminal] evalWithFormat:@"UIALogger.logDebug('%@');", [debug slStringByEscapingForJavaScriptLiteral]];
}

- (void)logMessage:(NSString *)message {
    if (![self currentQueueIsLoggingQueue]) {
        dispatch_sync(_loggingQueue, ^{
            [self logMessage:message];
        });
        return;
    }

    [[SLTerminal sharedTerminal] evalWithFormat:@"UIALogger.logMessage('%@');", [message slStringByEscapingForJavaScriptLiteral]];
}

- (void)logWarning:(NSString *)warning {
    if (![self currentQueueIsLoggingQueue]) {
        dispatch_sync(_loggingQueue, ^{
            [self logWarning:warning];
        });
        return;
    }

    [[SLTerminal sharedTerminal] evalWithFormat:@"UIALogger.logWarning('%@');", [warning slStringByEscapingForJavaScriptLiteral]];
}

- (void)logError:(NSString *)error {
    if (![self currentQueueIsLoggingQueue]) {
        dispatch_sync(_loggingQueue, ^{
            [self logError:error];
        });
        return;
    }

    [[SLTerminal sharedTerminal] evalWithFormat:@"UIALogger.logError('%@');", [error slStringByEscapingForJavaScriptLiteral]];
}

@end


@implementation SLLogger (SLTestController)

- (void)logTestingStart {
    [self logMessage:@"Testing started."];
}

- (void)logTestStart:(NSString *)test {
    [self logMessage:[NSString stringWithFormat:@"Test \"%@\" started.", test]];
}

- (void)logTestFinish:(NSString *)test
 withNumCasesExecuted:(NSUInteger)numCasesExecuted
       numCasesFailed:(NSUInteger)numCasesFailed
       numCasesFailedUnexpectedly:(NSUInteger)numCasesFailedUnexpectedly {
    [self logMessage:[NSString stringWithFormat:@"Test \"%@\" finished: executed %lu case%@, with %lu failure%@ (%lu unexpected).",
                                                test, (unsigned long)numCasesExecuted, (numCasesExecuted == 1 ? @"" : @"s"),
                                                      (unsigned long)numCasesFailed, (numCasesFailed == 1 ? @"" : @"s"), (unsigned long)numCasesFailedUnexpectedly]];
}

- (void)logTestAbort:(NSString *)test {
    [self logMessage:[NSString stringWithFormat:@"Test \"%@\" terminated abnormally.", test]];
}

- (void)logTestingFinishWithNumTestsExecuted:(NSUInteger)numTestsExecuted
                              numTestsFailed:(NSUInteger)numTestsFailed {
    [self logMessage:[NSString stringWithFormat:@"Testing finished: executed %lu test%@, with %lu failure%@.",
                                                (unsigned long)numTestsExecuted, (numTestsExecuted == 1 ? @"" : @"s"),
                                                (unsigned long)numTestsFailed, (numTestsFailed == 1 ? @"" : @"s")]];
}

- (void)logUncaughtException:(NSException *)exception {
    NSMutableString *exceptionMessage = [[NSMutableString alloc] initWithString:@"Uncaught exception occurred"];
    [exceptionMessage appendFormat:@": ***%@***", [exception name]];
    NSString *exceptionReason = [exception reason];
    if ([exceptionReason length]) {
        [exceptionMessage appendFormat:@" for reason: %@", exceptionReason];
    }

    [self logError:exceptionMessage];
}

@end


@implementation SLLogger (SLTest)

- (void)logException:(NSException *)exception expected:(BOOL)expected {
    NSString *callSite;
    NSString *fileName = [exception userInfo][SLLoggerExceptionFilenameKey];
    NSNumber *lineNumber = [exception userInfo][SLLoggerExceptionLineNumberKey];
    if (fileName && lineNumber) {
        callSite = [NSString stringWithFormat:@"%@:%d", fileName, [lineNumber intValue]];
    } else {
        callSite = SLLoggerUnknownCallSite;
    }

    NSString *exceptionDescription;
    if (expected) {
        exceptionDescription = [exception reason];
    } else {
        exceptionDescription = [NSString stringWithFormat:@"Unexpected exception occurred ***%@*** for reason: %@",
                                [exception name], [exception reason]];
    }

    NSString *message = [NSString stringWithFormat:@"%@: %@", callSite, exceptionDescription];
    [[SLLogger sharedLogger] logError:message];
}

- (void)logTest:(NSString *)test caseStart:(NSString *)testCase {
    if (![self currentQueueIsLoggingQueue]) {
        dispatch_sync(_loggingQueue, ^{
            [self logTest:test caseStart:testCase];
        });
        return;
    }

    [[SLTerminal sharedTerminal] evalWithFormat:@"UIALogger.logStart('Test case \"-[%@ %@]\" started.');", test, testCase];
}

- (void)logTest:(NSString *)test caseFail:(NSString *)testCase expected:(BOOL)expected {
    if (![self currentQueueIsLoggingQueue]) {
        dispatch_sync(_loggingQueue, ^{
            [self logTest:test caseFail:testCase expected:expected];
        });
        return;
    }

    if (expected) {
        [[SLTerminal sharedTerminal] evalWithFormat:@"UIALogger.logFail('Test case \"-[%@ %@]\" failed.');", test, testCase];
    } else {
        [[SLTerminal sharedTerminal] evalWithFormat:@"UIALogger.logIssue('Test case \"-[%@ %@]\" failed unexpectedly.');", test, testCase];
    }
}

- (void)logTest:(NSString *)test casePass:(NSString *)testCase {
    if (![self currentQueueIsLoggingQueue]) {
        dispatch_sync(_loggingQueue, ^{
            [self logTest:test casePass:testCase];
        });
        return;
    }

    [[SLTerminal sharedTerminal] evalWithFormat:@"UIALogger.logPass('Test case \"-[%@ %@]\" passed.');", test, testCase];
}

@end
