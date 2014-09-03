//
//  SIReporter.h
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

#import <Foundation/Foundation.h>

#import "SISLLogEvents.h"

/**
 `SIReporter` is the abstract base class for objects that write Subliminal log
 events to standard output and error in different formats.
 
 Concrete base classes define specific formats and perform the work of writing
 formatted events to standard output and error.
 */
@interface SIReporter : NSObject

/**
 The standard output file used by the receiver.
 
 Standard output is where the reporter should send its output.

 Set by the base class when `-beginReportingWithStandardOutput:standardError:` is called.
 */
@property (nonatomic, readonly) NSFileHandle *standardOutput;

/**
 The standard error file used by the receiver.
 
 Standard error is where the reporter should send diagnostic messages.
 
 Set by the base class when `-openWithStandardOutput:standardError:` is called.
 */
@property (nonatomic, readonly) NSFileHandle *standardError;

/**
 Sent to the receiver before it is asked to report any events.

 The base class sets `standardOutput` and `standardError`.
 Subclasses may override to perform other initialization work.
 Subclasses must call `super` from their implementation.
 
 @param standardOutput The standard output for the receiver.
 @param standardError The standard error for the receiver.
 */
- (void)beginReportingWithStandardOutput:(NSFileHandle *)standardOutput
                           standardError:(NSFileHandle *)standardError;

/**
 Sent to the receiver when an event occurs.
 
 The receiver may write a formatted representation of the event
 to `standardOutput` or `standardError`.
 
 @param event   The event to report. `SISLLogParser.h` describes the event format.
 */
- (void)reportEvent:(NSDictionary *)event;

/**
 Sent to the receiver after all events have been reported.

 This is a no-op in the base class. Subclasses may override to
 perform tear-down work. They should not close `standardOutput`
 nor `standardError`, as it is the client rather than the reporter
 which opens those files.
 */
- (void)finishReporting;

@end
