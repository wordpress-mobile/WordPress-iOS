//
//  SIOptionsTests.m
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

#import "SIOptions.h"

@interface SIOptionsTests : SenTestCase

@end

@implementation SIOptionsTests

- (SIOptions *)optionsFrom:(NSArray *)arguments {
    SIOptions *options = [[SIOptions alloc] init];

    NSError *parseError = nil;
    if (![options parseArguments:arguments error:&parseError]) {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Could not parse arguments: %@", parseError];
    }

    return options;
}

- (void)testNoArgumentsSetsHelpFlag {
    STAssertTrue([[self optionsFrom:@[]] showHelp], @"Parsing an empty arguments string should se the help flag.");
}

- (void)testHelpOptionSetsHelpFlag {
    STAssertTrue([[self optionsFrom:@[ @"--help" ]] showHelp], @"The `--help` option did not cause the help flag to be set.");
}

- (void)testUnrecognizedArgumentsAreAssumedToBeInstrumentsArguments {
    NSArray *expectedInstrumentsArguments = @[ @"-D", @"Integration Tests.trace", @"-l", @"100000", @"Integration Tests.app", @"-e", @"UIARESULTSPATH", @"foo" ];
    NSArray *arguments = [expectedInstrumentsArguments arrayByAddingObject:@"--help"];

    STAssertEqualObjects([[self optionsFrom:arguments] instrumentsArguments], expectedInstrumentsArguments,
                         @"Instruments arguments were not parsed as expected.");
}

- (void)testTemplateOptionIsProhibited {
    STAssertThrows([self optionsFrom:(@[ @"-t", @"foo.tracetemplate" ])],
                   @"Options parsing should reject the template option.");
}

@end
