//
//  SISLLogParser.m
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

#import "SISLLogParser.h"

#import "SISLLogEvents.h"

@implementation SISLLogParser {
    NSString *_currentTest, *_currentTestCase;
}

+ (NSDateFormatter *)iso8601DateFormatter {
    static NSDateFormatter *__formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __formatter = [[NSDateFormatter alloc] init];
        // produce invariant results: see https://developer.apple.com/library/ios/qa/qa1480/_index.html
        NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        [__formatter setLocale:enUSPOSIXLocale];
        [__formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    });
    return __formatter;
}

+ (void)parseMessageType:(NSString **)messageType andMessage:(NSString **)message fromLine:(NSString *)line {
    NSParameterAssert(messageType && message && line);

    static NSRegularExpression *__instrumentsLogExpression = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *instrumentsLogPattern = @"^(?:\\d+-\\d+-\\d+ \\d+:\\d+:\\d+ \\+\\d+) (.+?): (.+)$";
        __instrumentsLogExpression = [[NSRegularExpression alloc] initWithPattern:instrumentsLogPattern
                                                                          options:0 error:NULL];
    });

    NSTextCheckingResult *result = [__instrumentsLogExpression firstMatchInString:line
                                                                          options:0 range:NSMakeRange(0, [line length])];
    if (result) {
        // the zeroth range is for the whole result
        *messageType = [line substringWithRange:[result rangeAtIndex:1]];
        *message = [line substringWithRange:[result rangeAtIndex:2]];
    } else {
        // e.g. the message didn't have a timestamp
        *messageType = nil;
        *message =  line;
    }
}

+ (void)parseEventType:(SISLLogEventType *)type subtype:(SISLLogEventSubtype *)subtype info:(NSDictionary **)info
       fromMessageType:(NSString *)messageType andMessage:(NSString *)message {
    NSParameterAssert(type && subtype && message);

    SISLLogEventType typeValue;
    SISLLogEventSubtype subtypeValue;
    NSMutableDictionary *infoValue = [[NSMutableDictionary alloc] init];

    if (messageType) {
        if ([messageType isEqualToString:@"Debug"]) {
            typeValue = SISLLogEventTypeDebug;
            subtypeValue = SISLLogEventSubtypeNone;
        } else if ([messageType isEqualToString:@"Warning"]) {
            typeValue = SISLLogEventTypeWarning;
            subtypeValue = SISLLogEventSubtypeNone;
        } else {
            static NSRegularExpression *__testExpression = nil, *__testCaseExpression = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                // TODO: Handle errors, warnings
                NSString *testPattern = @"Test \"(.*)\" (started\\.|terminated abnormally\\.|finished: executed (\\d+) case(?:s)?, with (\\d+) failure(?:s)? \\((\\d+) unexpected\\)\\.)";
                __testExpression = [[NSRegularExpression alloc] initWithPattern:testPattern options:0 error:NULL];

                NSString *testCasePattern = @"Test case \"-\\[.+ (.+)\\]\" (started|passed|failed|failed unexpectedly)\\.";
                __testCaseExpression = [[NSRegularExpression alloc] initWithPattern:testCasePattern options:0 error:NULL];
            });

            NSRange messageRange = NSMakeRange(0, [message length]);
            NSTextCheckingResult *testMatch = [__testExpression firstMatchInString:message options:0 range:messageRange];
            NSTextCheckingResult *testCaseMatch = testMatch ? nil : [__testCaseExpression firstMatchInString:message options:0 range:messageRange];

            // Assume that the message is test-status related to reduce duplication.
            typeValue = SISLLogEventTypeTestStatus;

            if (testMatch) {
                // The zeroth range corresponds to the match as a whole.
                infoValue[@"test"] = [message substringWithRange:[testMatch rangeAtIndex:1]];

                NSString *status = [message substringWithRange:[testMatch rangeAtIndex:2]];
                if ([status hasPrefix:@"started"]) {
                    subtypeValue = SISLLogEventSubtypeTestStarted;
                } else if ([status hasPrefix:@"terminated abnormally"]) {
                    subtypeValue = SISLLogEventSubtypeTestTerminatedAbnormally;
                } else {    // finished
                    subtypeValue = SISLLogEventSubtypeTestFinished;

                    infoValue[@"numCasesExecuted"] = @([[message substringWithRange:[testMatch rangeAtIndex:3]] integerValue]);
                    infoValue[@"numCasesFailed"] = @([[message substringWithRange:[testMatch rangeAtIndex:4]] integerValue]);
                    infoValue[@"numCasesFailedUnexpectedly"] = @([[message substringWithRange:[testMatch rangeAtIndex:5]] integerValue]);
                }
            } else if (testCaseMatch) {
                // The zeroth range corresponds to the match as a whole.
                infoValue[@"testCase"] = [message substringWithRange:[testCaseMatch rangeAtIndex:1]];

                NSString *status = [message substringWithRange:[testCaseMatch rangeAtIndex:2]];
                if ([status isEqualToString:@"started"]) {
                    subtypeValue = SISLLogEventSubtypeTestCaseStarted;
                } else if ([status isEqualToString:@"passed"]) {
                    subtypeValue = SISLLogEventSubtypeTestCasePassed;
                } else if ([status isEqualToString:@"failed"]){
                    subtypeValue = SISLLogEventSubtypeTestCaseFailed;
                } else {    // failed unexpectedly
                    subtypeValue = SISLLogEventSubtypeTestCaseFailedUnexpectedly;
                }
            } else if ([message hasPrefix:@"Testing started"]) {
                subtypeValue = SISLLogEventSubtypeTestingStarted;
            } else if ([message hasPrefix:@"Testing finished"]) {
                subtypeValue = SISLLogEventSubtypeTestingFinished;

                static NSRegularExpression *__testingFinishedExpression = nil;
                static dispatch_once_t onceToken;
                dispatch_once(&onceToken, ^{
                    NSString *testingFinishedPattern = @".+executed (\\d+) test(?:s)?, with (\\d+) failure(?:s)?\\.";
                    __testingFinishedExpression = [[NSRegularExpression alloc] initWithPattern:testingFinishedPattern options:0 error:NULL];
                });

                NSTextCheckingResult *testingFinishedMatch = [__testingFinishedExpression firstMatchInString:message options:0 range:messageRange];
                // Don't abort parsing by throwing an assert; unit tests verify consistency.
                if (testingFinishedMatch) {
                    // The zeroth range corresponds to the match as a whole.
                    infoValue[@"numTestsExecuted"] = @([[message substringWithRange:[testingFinishedMatch rangeAtIndex:1]] integerValue]);
                    infoValue[@"numTestsFailed"] = @([[message substringWithRange:[testingFinishedMatch rangeAtIndex:2]] integerValue]);
                }
            } else if ([messageType isEqualToString:@"Error"]) {
                if (([message rangeOfString:@"^.*: Unexpected exception occurred" options:NSRegularExpressionSearch].location != NSNotFound) ||
                    ([message hasPrefix:@"Uncaught exception occurred"])) {
                    subtypeValue = SISLLogEventSubtypeTestError;
                } else {
                    subtypeValue = SISLLogEventSubtypeTestFailure;

                    // message format: "SLKeyboardTest.m:62: ..."
                    NSArray *messageComponents = [message componentsSeparatedByString:@":"];
                    infoValue[@"fileName"] = messageComponents[0];
                    infoValue[@"lineNumber"] = @([messageComponents[1] integerValue]);
                }
            } else {
                typeValue = SISLLogEventTypeDefault;
                subtypeValue = SISLLogEventSubtypeNone;
            }
        }
    } else {
        typeValue = SISLLogEventTypeDefault;
        subtypeValue = SISLLogEventSubtypeNone;
    }

    *type = typeValue;
    *subtype = subtypeValue;
    *info = [infoValue count] ? [infoValue copy] : nil;
}

// This method reads test (case) names out of "test (case)-beginning" events
// and saves them to apply to events occurring between those events and "test (case)-ending" events.
- (void)synchronizeTestStateWithEvent:(NSMutableDictionary *)event {
    // Determine the test and test case to apply to _event_, but don't override the actual values as they change
    NSString *currentTest = event[@"info"][@"test"] ?: _currentTest;
    _currentTest = currentTest;
    NSString *currentTestCase = event[@"info"][@"testCase"] ?: _currentTestCase;
    _currentTestCase = currentTestCase;

    // Clear the cached test and test case as necessary;
    // in most cases we will apply the cached values to the current event
    // --"test (case)-ending" events are still considered to be part of their test (case).
    // Also set special test case values.
    if ([event[@"type"] unsignedIntegerValue] == SISLLogEventTypeTestStatus) {
        switch ([event[@"subtype"] unsignedIntegerValue]) {
            case SISLLogEventSubtypeTestStarted:
                // all messages after test start and before test case start are considered to be part of test set-up
                _currentTestCase = @"setUpTest";
                break;
            case SISLLogEventSubtypeTestCasePassed:
            case SISLLogEventSubtypeTestCaseFailed:
            case SISLLogEventSubtypeTestCaseFailedUnexpectedly:
                // all messages after test case finish and before test finish are considered to be part of test tear-down
                _currentTestCase = @"tearDownTest";
                break;
            case SISLLogEventSubtypeTestFinished:
            case SISLLogEventSubtypeTestTerminatedAbnormally:
                _currentTest = nil;
                _currentTestCase = nil;
                // since all test cases have finished, don't use the cached test case value
                currentTestCase = nil;
                break;
            default:
                break;
        }
    }

    NSMutableDictionary *mutableInfo = [[NSMutableDictionary alloc] initWithDictionary:event[@"info"]];
    if (currentTest) mutableInfo[@"test"] = currentTest;
    if (currentTestCase) mutableInfo[@"testCase"] = currentTestCase;
    if ([mutableInfo count]) event[@"info"] = [mutableInfo copy];
}

+ (BOOL)shouldFilterStdoutLine:(NSString *)line {
    // filter the trace-completed message: the tests have already completed
    return [line rangeOfString:@"Instruments Trace Complete"].location != NSNotFound;
}

- (void)parseStdoutLine:(NSString *)line {
    if ([[self class] shouldFilterStdoutLine:line]) return;

    // we use our own timestamps rather than the timestamp in the line
    // because we can't guarantee that error messages (as parsed in `-parseStderrLine:`) will have timestamps
    NSString *timestamp = [[[self class] iso8601DateFormatter] stringFromDate:[NSDate date]];

    NSString *messageType = nil, *message = nil;
    [[self class] parseMessageType:&messageType andMessage:&message fromLine:line];

    SISLLogEventType eventType;
    SISLLogEventSubtype eventSubtype;
    NSDictionary *info = nil;
    [[self class] parseEventType:&eventType subtype:&eventSubtype info:&info fromMessageType:messageType andMessage:message];

    NSMutableDictionary *event = [[NSMutableDictionary alloc] initWithDictionary:@{
        @"timestamp": timestamp,
        @"type": @(eventType),
        @"subtype": @(eventSubtype),
        @"message": message
    }];
    if (info) event[@"info"] = info;

    [self synchronizeTestStateWithEvent:event];
    [self.delegate parser:self didParseEvent:[event copy]];
}

+ (BOOL)shouldFilterStderrLine:(NSString *)line {
    // filter diagnostic messages from "ScriptAgent"
    return [line rangeOfString:@"ScriptAgent"].location != NSNotFound;
}

- (void)parseStderrLine:(NSString *)line {
    if ([[self class] shouldFilterStderrLine:line]) return;

    // we use our own timestamps rather than the timestamp in the line
    // because we can't guarantee that error messages will have timestamps
    NSString *timestamp = [[[self class] iso8601DateFormatter] stringFromDate:[NSDate date]];

    NSMutableDictionary *event = [[NSMutableDictionary alloc] initWithDictionary:@{
        @"timestamp": timestamp,
        @"type": @(SISLLogEventTypeError),
        @"subtype": @(SISLLogEventSubtypeNone),
        @"message": line
    }];

    [self synchronizeTestStateWithEvent:event];
    [self.delegate parser:self didParseEvent:[event copy]];
}

@end
