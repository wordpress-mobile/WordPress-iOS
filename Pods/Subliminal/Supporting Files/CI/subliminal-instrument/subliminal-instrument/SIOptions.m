//
//  SIOptions.m
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

#import "SIOptions.h"

#import "SITerminalReporter.h"

static NSString *const SIOptionsErrorDomain = @"SIOptionsError";

@implementation SIOptions

+ (NSString *)usagePattern {
    return @"[--help] [INSTRUMENTS ARGUMENTS]";
}

+ (NSString *)optionDescriptions {
    static NSString *const indentString = @"    ";
    static const NSUInteger descriptionStartIndex = 27;

    NSMutableString *usageString = [[NSMutableString alloc] init];

    NSString *helpOptionString = [NSString stringWithFormat:@"%@%@", indentString, @"--help"];
    [usageString appendString:[helpOptionString stringByPaddingToLength:descriptionStartIndex withString:@" " startingAtIndex:0]];
    [usageString appendFormat:@"%@\n", @"Show help."];

    NSString *instrumentsArgumentsString = [NSString stringWithFormat:@"%@%@", indentString, @"INSTRUMENTS ARGUMENTS"];
    [usageString appendString:[instrumentsArgumentsString stringByPaddingToLength:descriptionStartIndex withString:@" " startingAtIndex:0]];
    [usageString appendString:@"Arguments to the `instruments` CLI tool (see `instruments(1)`).\n"];
    [usageString appendString:[@"" stringByPaddingToLength:descriptionStartIndex withString:@" " startingAtIndex:0]];
    [usageString appendString:@"All arguments are valid except for the template option, `-t`:\n"];
    [usageString appendString:[@"" stringByPaddingToLength:descriptionStartIndex withString:@" " startingAtIndex:0]];
    [usageString appendString:@"`subliminal-instrument` incorporates the template to run.\n"];

    return usageString;
}

+ (NSError *)errorWithDescription:(NSString *)description {
    NSParameterAssert(description);
    return [NSError errorWithDomain:SIOptionsErrorDomain
                               code:0
                           userInfo:@{ NSLocalizedDescriptionKey: description }];
}

- (id)init {
    self = [super init];
    if (self) {
        _reporters = @[ [[SITerminalReporter alloc] init] ];
    }
    return self;
}

- (BOOL)parseArguments:(NSArray *)arguments error:(NSError *__autoreleasing *)error {
    if (![arguments count]) {
        _showHelp = YES;
        return YES;
    }

    NSError *localError = nil;

    NSMutableArray *mutableArguments = [[NSMutableArray alloc] initWithArray:arguments];
    BOOL argumentsAreValid = [self consumeSIArguments:mutableArguments error:&localError] &&
                             [self consumeInstrumentsArguments:mutableArguments error:&localError];

    if (error) *error = localError;
    return argumentsAreValid;
}

- (BOOL)consumeSIArguments:(NSMutableArray *)arguments error:(NSError *__autoreleasing *)error {
    NSString *const kHelpOption = @"--help";

    NSParameterAssert(error);

    if (![arguments count]) return YES;

    if ([arguments containsObject:kHelpOption]) {
        _showHelp = YES;
        [arguments removeObject:kHelpOption];
    }

    return YES;
}

- (BOOL)consumeInstrumentsArguments:(NSMutableArray *)arguments error:(NSError *__autoreleasing *)error {
    NSParameterAssert(error);

    if ([arguments containsObject:@"-t"]) {
        *error = [[self class] errorWithDescription:@"A template (-t) must not be specified (`subliminal-instrument` incorporates the template to run)."];
        return NO;
    }

    _instrumentsArguments = [arguments copy];
    return YES;
}

@end
