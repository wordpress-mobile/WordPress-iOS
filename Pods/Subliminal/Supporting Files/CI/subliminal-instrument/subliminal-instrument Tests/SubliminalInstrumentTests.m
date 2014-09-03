//
//  SubliminalInstrumentTests.m
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

#import <SenTestingKit/SenTestingKit.h>

#import "SubliminalInstrument.h"
#import "NSPipe+Utilities.h"

@interface SubliminalInstrumentTests : SenTestCase

@end

@implementation SubliminalInstrumentTests

#pragma mark - Utilities

- (NSDictionary *)runInstrumentAndCaptureOutput:(SubliminalInstrument *)instrument {
    NSPipe *stdOutPipe = [NSPipe pipe],
           *stdErrPipe = [NSPipe pipe];
    [stdOutPipe beginReadingInBackground];
    [stdErrPipe beginReadingInBackground];

    // Run the instrument.
    instrument.standardOutput = [stdOutPipe fileHandleForWriting];
    instrument.standardError = [stdErrPipe fileHandleForWriting];
    [instrument run];

    [stdOutPipe finishReading];
    [stdErrPipe finishReading];

    NSString *stdOut = [[NSString alloc] initWithData:stdOutPipe.availableData encoding:NSUTF8StringEncoding],
             *stdErr = [[NSString alloc] initWithData:stdErrPipe.availableData encoding:NSUTF8StringEncoding];

    return @{ @"stdout": stdOut, @"stderr": stdErr };
}

#pragma mark - Tests

- (void)testCallingWithHelpPrintsUsage {
    SubliminalInstrument *instrument = [[SubliminalInstrument alloc] init];
    instrument.arguments = @[ @"--help" ];

    NSDictionary *result = [self runInstrumentAndCaptureOutput:instrument];

    STAssertEquals(instrument.terminationStatus, 1, @"Instrument should have exited with an error status.");
    STAssertTrue([result[@"stderr"] hasPrefix:@"usage: subliminal-instrument"], @"Instrument should have printed usage on stderr.");
}

- (void)testCallingWithNoArgsPrintsUsage {
    SubliminalInstrument *instrument = [[SubliminalInstrument alloc] init];

    NSDictionary *result = [self runInstrumentAndCaptureOutput:instrument];

    STAssertEquals(instrument.terminationStatus, 1, @"Instrument should have exited with an error status.");
    STAssertTrue([result[@"stderr"] hasPrefix:@"usage: subliminal-instrument"], @"Instrument should have printed usage on stderr.");
}

@end
