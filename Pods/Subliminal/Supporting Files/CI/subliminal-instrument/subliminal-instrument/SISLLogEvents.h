//
//  SISLLogEvents.h
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

#ifndef subliminal_instrument_SISLLogEvents_h
#define subliminal_instrument_SISLLogEvents_h

/**
 Each event is a dictionary with the following fields:

 *   `timestamp`:   the date-time at which the event occurred,
                    as an `NSString *` in ISO 8601 format.
 *   `type`:        the type of the event, as an `NSNumber`
                    wrapping a value of type `SISLLogEventType`.
 *   `subtype`:     the subtype of the event, as an `NSNumber` wrapping a value
                    of type `SISLLogEventSubtype`.
 *   `info`:        additional information about the event, as an `NSDictionary *`.
                    All events may contain a dictionary with the following fields:

                    * "test":       the test during which the event occurred,
                                    if a test was ongoing at the time that the event occurred.
                    * "testCase":   the test case during which the event occurred,
                                    if a test case was ongoing (either the test case itself,
                                    or its setup or teardown) at the time that the error occurred.
                                    If the error occurred in test set-up, this will be "setUpTest".
                                    If the error occurred in test tear-down, this will be "tearDownTest".

                    The dictionary may contain additional fields based on the event's subtype.
                    See `SISLLogEventSubtype`. This dictionary may be omitted
                    if it would be empty.
 *   `message`:     a message describing the event, as an `NSString *`
                    Oftentimes, the type, subtype, and info will convey the same
                    information as the message, but in a more structured manner.

 */
typedef NS_ENUM(NSUInteger, SISLLogEventType) {
    /**
     The default event type.

     Includes events that indicate messages logged by the tests
     that are not of the other types below.
     */
    SISLLogEventTypeDefault,

    /**
     The type of events that indicate that the `instruments` executable
     encountered an error.

     Events that indicate that the tests run by the executable encountered an error
     are of type `SISLLogEventTypeTestStatus`, with appropriate subtypes.
     */
    SISLLogEventTypeError,

    /** The type of events that indicate some change in the tests' state. */
    SISLLogEventTypeTestStatus,

    /** The type of events that indicate debug messages (as logged by the tests). */
    SISLLogEventTypeDebug,

    /** The type of events that indicate warning messages (as logged by the tests). */
    SISLLogEventTypeWarning
};

typedef NS_ENUM(NSUInteger, SISLLogEventSubtype) {
    /** The default event subtype. */
    SISLLogEventSubtypeNone,

    /**
     The subtype of events that indicate that the tests encountered
     an unexpected error, such as an uncaught exception.

     @see `SISLLogEventSubtypeTestFailure`
     */
    SISLLogEventSubtypeTestError,

    /**
     The subtype of events that indicate that a test assertion failed.

     Info:

     *   "fileName":     the name of the file in which the failure occurred,
     *   "lineNumber":   the line number (in `file`) at which the failure occurred,
                         as an `NSNumber *` wrapping an integer.

     @see `SISLLogEventSubtypeTestError`
     */
    SISLLogEventSubtypeTestFailure,

    /**
     The subtype of the event that indicates that testing has started.
     */
    SISLLogEventSubtypeTestingStarted,

    /**
     The subtype of events that indicate that particular tests have started.

     Info:
     
     * "test": the test that has started

     */
    SISLLogEventSubtypeTestStarted,

    /**
     The subtype of events that indicate that test cases have started.

     Info:
     
     * "testCase": the test case that has started

     */
    SISLLogEventSubtypeTestCaseStarted,

    /**
     The subtype of events that indicate that test cases have passed.

     Info:

     * "testCase": the test case that has passed

     */
    SISLLogEventSubtypeTestCasePassed,

    /**
     The subtype of events that indicate that test cases have failed
     (due to a test assertion failing).

     Info:
        
     * "testCase": the test case that has failed

     */
    SISLLogEventSubtypeTestCaseFailed,

    /**
     The subtype of events that indicate that test cases have failed
     unexpectedly (due to the test case encountering an exception other
     than that thrown by a test assertion failing).

     Info:

     * "testCase": the test case that has failed unexpectedly

     */
    SISLLogEventSubtypeTestCaseFailedUnexpectedly,

    /**
     The subtype of events that indicate that particular tests have finished.

     Info:

     *   "test":             the test that has finished,
     *   "numCasesExecuted": the number of cases that were executed,
                             as an `NSNumber *` wrapping an integer.
     *   "numCasesFailed":   of `numCasesExecuted`, the number of cases that failed,
                             as an `NSNumber *` wrapping an integer.
     *   "numCasesFailedUnexpectedly":   of `numCasesFailed`, the number of cases
                                         that failed unexpectedly, as an `NSNumber *`
                                         wrapping an integer.
     */
    SISLLogEventSubtypeTestFinished,

    /**
     The subtype of events that indicate that particular tests have terminated
     abnormally due to a failure or error in test set-up or tear-down.

     Info:

     *   "test": the test that has finished

     */
    SISLLogEventSubtypeTestTerminatedAbnormally,

    /**
     The subtype of events that indicate that testing has finished.

     Info:

     *   "numTestsExecuted": the number of tests that were executed,
                             as an `NSNumber *` wrapping an integer.
     *   "numTestsFailed":   Of `numTestsExecuted`, the number of tests that failed
                             (by throwing an exception in set-up, tear-down, or a test case).

     */
    SISLLogEventSubtypeTestingFinished
};

#endif
