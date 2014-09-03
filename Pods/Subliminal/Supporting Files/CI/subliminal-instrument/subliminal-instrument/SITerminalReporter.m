//
//  SITerminalReporter.m
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

#import "SITerminalReporter.h"

#import "SIFileReportWriter.h"

@interface SITerminalReporter ()
@end

@implementation SITerminalReporter {
    SIFileReportWriter *_outputWriter, *_errorWriter;
}

+ (NSString *)passIndicatorString {
    return @"<green><pass/></green>";
}

+ (NSString *)warningIndicatorString {
    return @"<yellow><warning/></yellow>";
}

+ (NSString *)failIndicatorString {
    return @"<red><fail/></red>";
}

+ (NSString *)placeholderIndicatorString {
    return @"<vbar/>";
}

- (void)beginReportingWithStandardOutput:(NSFileHandle *)standardOutput
                           standardError:(NSFileHandle *)standardError {
    [super beginReportingWithStandardOutput:standardOutput standardError:standardError];

    _outputWriter = [[SIFileReportWriter alloc] initWithOutputHandle:self.standardOutput];
    _errorWriter = [[SIFileReportWriter alloc] initWithOutputHandle:self.standardError];
}

- (void)reportEvent:(NSDictionary *)event {
    NSString *message = event[@"message"];

    // Certain log types are bracketed within their respective test/test cases.
    BOOL eventOccurredWithinTest = (event[@"info"][@"test"] != nil);

    switch ([event[@"type"] unsignedIntegerValue]) {
        case SISLLogEventTypeTestStatus:
            switch ([event[@"subtype"] unsignedIntegerValue]) {
                case SISLLogEventSubtypeNone:
                    NSAssert(NO, @"Unexpected event type and subtype: %lu, %lu.",
                             (unsigned long)SISLLogEventTypeTestStatus, (unsigned long)SISLLogEventSubtypeNone);
                    break;

                case SISLLogEventSubtypeTestError:
                case SISLLogEventSubtypeTestFailure: {
                    if (eventOccurredWithinTest) _outputWriter.dividerActive = YES;

                    // Since the message will be terminal-formatted, we must escape potential XML entities in the message.
                    NSString *escapedMessage = CFBridgingRelease(CFXMLCreateStringByEscapingEntities(kCFAllocatorDefault, (__bridge CFStringRef)message, NULL));

                    [_outputWriter printLine:@"%@", escapedMessage];
                    break;
                }

                case SISLLogEventSubtypeTestingStarted:
                    [_outputWriter printLine:@"%@", message];
                    // offset the tests
                    [_outputWriter printNewline];
                    _outputWriter.indentLevel++;
                    break;
                case SISLLogEventSubtypeTestStarted:
                    [_outputWriter printLine:@"<ul>%@</ul> started.", event[@"info"][@"test"]];
                    _outputWriter.indentLevel++;
                    break;

                case SISLLogEventSubtypeTestCaseStarted:
                    // close the test-setup section if present
                    _outputWriter.dividerActive = NO;
                    // So that the pass or fail message can overwrite this,
                    // leave room for an indicator at the beginning and don't print a newline.
                    [_outputWriter updateLine:@"%@ \"%@\" started.", [[self class] placeholderIndicatorString], event[@"info"][@"testCase"]];
                    break;

                case SISLLogEventSubtypeTestCasePassed:
                case SISLLogEventSubtypeTestCaseFailed:
                case SISLLogEventSubtypeTestCaseFailedUnexpectedly: {
                    // close the test case section
                    _outputWriter.dividerActive = NO;

                    NSString *statusIndicatorString, *finishDescription;
                    switch (([event[@"subtype"] unsignedIntegerValue])) {
                        case SISLLogEventSubtypeTestCasePassed:
                            statusIndicatorString = [[self class] passIndicatorString];
                            finishDescription = @"passed";
                            break;
                        case SISLLogEventSubtypeTestCaseFailed:
                        case SISLLogEventSubtypeTestCaseFailedUnexpectedly:
                            statusIndicatorString = [[self class] failIndicatorString];
                            if ([event[@"subtype"] unsignedIntegerValue] == SISLLogEventSubtypeTestCaseFailed) {
                                finishDescription =  @"failed";
                            } else {
                                finishDescription = @"failed unexpectedly";
                            }
                            break;
                        default:
                            NSAssert(NO, @"Should not have reached this point.");
                            break;
                    }
                    // This will overwrite the test case-started message.
                    [_outputWriter printLine:@"%@ \"%@\" %@.",
                                             statusIndicatorString, event[@"info"][@"testCase"], finishDescription];
                    break;
                }


                case SISLLogEventSubtypeTestFinished:
                case SISLLogEventSubtypeTestTerminatedAbnormally: {
                    // close the test-teardown section if present
                    _outputWriter.dividerActive = NO;

                    NSString *test = event[@"info"][@"test"];
                    NSString *formattedMessage;
                    if ([event[@"subtype"] unsignedIntegerValue] == SISLLogEventSubtypeTestFinished) {
                        NSUInteger  numCasesExecuted = [event[@"info"][@"numCasesExecuted"] unsignedIntegerValue],
                                    numCasesFailed = [event[@"info"][@"numCasesFailed"] unsignedIntegerValue],
                                    numCasesFailedUnexpectedly = [event[@"info"][@"numCasesFailedUnexpectedly"] unsignedIntegerValue];
                        NSString *statusIndicatorString;
                        if (numCasesFailed || numCasesFailedUnexpectedly) {
                            statusIndicatorString = [[self class] failIndicatorString];
                        } else {
                            statusIndicatorString = [[self class] passIndicatorString];
                        }
                        formattedMessage = [NSString stringWithFormat:@"%@ %@ finished: executed %lu case%@, with %lu failure%@ (%lu unexpected).",
                                                                        statusIndicatorString, test, (unsigned long)numCasesExecuted, (numCasesExecuted == 1 ? @"" : @"s"),
                                                                        (unsigned long)numCasesFailed, (numCasesFailed == 1 ? @"" : @"s"), (unsigned long)numCasesFailedUnexpectedly];
                    } else {
                        formattedMessage = [NSString stringWithFormat:@"%@ %@ terminated abnormally.", [[self class] failIndicatorString], test];
                    }
                    [_outputWriter printLine:@"%@", formattedMessage];

                    // only now update the indent level, so that test-finish and terminates-abnormally messages
                    // are logged at the same level as the test cases
                    _outputWriter.indentLevel--;
                    // separate the tests by a newline
                    [_outputWriter printNewline];
                    break;
                }

                case SISLLogEventSubtypeTestingFinished:
                    _outputWriter.indentLevel--;

                    NSUInteger  numTestsExecuted = [event[@"info"][@"numTestsExecuted"] unsignedIntegerValue],
                                numTestsFailed = [event[@"info"][@"numTestsFailed"] unsignedIntegerValue];
                    NSString *statusIndicatorString;
                    if (numTestsFailed) {
                        statusIndicatorString = [[self class] failIndicatorString];
                    } else {
                        statusIndicatorString = [[self class] passIndicatorString];
                    }
                    [_outputWriter printLine:@"%@ Testing finished: executed %lu test%@, with %lu failure%@.",
                                             statusIndicatorString, (unsigned long)numTestsExecuted, (numTestsExecuted == 1 ? @"" : @"s"),
                                             (unsigned long)numTestsFailed, (numTestsFailed == 1 ? @"" : @"s")];
                    break;
            }
            break;

        case SISLLogEventTypeDefault:
        case SISLLogEventTypeDebug:
        case SISLLogEventTypeWarning: {
            // Since the message will be terminal-formatted, we must escape potential XML entities in the message.
            NSString *escapedMessage = CFBridgingRelease(CFXMLCreateStringByEscapingEntities(kCFAllocatorDefault, (__bridge CFStringRef)message, NULL));

            if (eventOccurredWithinTest) _outputWriter.dividerActive = YES;
            NSString *formattedMessage;
            if ([event[@"type"] unsignedIntegerValue] == SISLLogEventTypeWarning) {
                formattedMessage = [NSString stringWithFormat:@"%@ %@", [[self class] warningIndicatorString], escapedMessage];
            } else {
                formattedMessage = escapedMessage;
            }

            [_outputWriter printLine:@"%@", formattedMessage];
            break;
        }
        case SISLLogEventTypeError: {
            // Since the message will be terminal-formatted, we must escape potential XML entities in the message.
            NSString *escapedMessage = CFBridgingRelease(CFXMLCreateStringByEscapingEntities(kCFAllocatorDefault, (__bridge CFStringRef)message, NULL));

            [_errorWriter printLine:@"ERROR: %@", escapedMessage];
            break;
        }
    }
}

@end
