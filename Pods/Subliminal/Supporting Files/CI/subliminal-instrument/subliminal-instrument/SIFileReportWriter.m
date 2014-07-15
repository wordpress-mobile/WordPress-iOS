//
//  SIFileReportWriter.m
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

#import "SIFileReportWriter.h"

#import <sys/ioctl.h>

#import "NSFileHandle+StringWriting.h"
#import "NSTask+Utilities.h"
#import "SITerminalStringFormatter.h"

static const NSUInteger kIndentSize = 4;
static const NSUInteger kDefaultWidth = 80;

@implementation SIFileReportWriter {
    NSFileHandle *_outputHandle;
    BOOL _outputHandleIsATerminal;
    NSString *_indentString;
    NSUInteger _dividerWidth;
    NSString *_currentLine, *_pendingLine;
    SITerminalStringFormatter *_outputFormatter;
}

+ (BOOL)environmentIsATerminal {
    static BOOL __environmentIsATerminal = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __environmentIsATerminal = (getenv("TERM") != NULL);
    });
    return __environmentIsATerminal;
}

/**
 Regarding the three class methods below:

 I don't think there's any guarantee that the terminal environment in which `tput`
 runs will be the same as as the environment to which a writer instance (with a
 terminal-directed output handle) will write, but I don't know how to fix that
 and it's probably safe to assume that the environments are the same.
 */
+ (NSString *)clearToEOLCharacter {
    // `tput` will fail below if we're not running in a terminal
    if (![self environmentIsATerminal]) return nil;

    static NSString *__clearToEOLCharacter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSTask *clearToEOLCharacterTask = [[NSTask alloc] init];
        clearToEOLCharacterTask.launchPath = @"/usr/bin/tput";
        clearToEOLCharacterTask.arguments = @[ @"el" ];
        __clearToEOLCharacter = [[clearToEOLCharacterTask output] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    });
    return __clearToEOLCharacter;
}

+ (BOOL)environmentSupportsColors {
    // `tput` will fail below if we're not running in a terminal
    if (![self environmentIsATerminal]) return NO;

    static BOOL __environmentSupportsColors = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // method suggested by http://stackoverflow.com/a/12760577/495611
        // we could theoretically call `tputs` directly but this is sooo much easier
        NSTask *tputColorsTask = [[NSTask alloc] init];
        tputColorsTask.launchPath = @"/usr/bin/tput";
        tputColorsTask.arguments = @[ @"colors" ];
        NSInteger numberOfColorsSupported = [[tputColorsTask output] integerValue];
        __environmentSupportsColors = (numberOfColorsSupported >= 8);
    });
    return __environmentSupportsColors;
}

+ (BOOL)environmentSupportsUnicode {
    static BOOL __environmentSupportsUnicode = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
#if DEBUG
        // The Xcode console does support Unicode even though the technique below fails
        __environmentSupportsUnicode = YES;
#else
        if (getenv("TRAVIS")) {
            // Travis supports Unicode even though the technique below fails
            __environmentSupportsUnicode = YES;
        } else {
            // from http://rosettacode.org/wiki/Terminal_control/Unicode_output#C
            char *lang = getenv("LANG");
            __environmentSupportsUnicode = (lang &&
                                            ([[@(lang) lowercaseString] rangeOfString:@"utf"].location != NSNotFound));
        }
#endif
    });
    return __environmentSupportsUnicode;
}

- (instancetype)initWithOutputHandle:(NSFileHandle *)outputHandle {
    NSParameterAssert(outputHandle);

    self = [super init];
    if (self) {
        _outputHandle = outputHandle;

        // We need to check both `isatty` and whether we're running in a terminal environment
        // because when running in Xcode, `isatty` will return true for `stdout`,
        // even though neither `ioctl` nor `tput` will work.
        int handleDescriptor = [_outputHandle fileDescriptor];
        _outputHandleIsATerminal = isatty(handleDescriptor) && [[self class] environmentIsATerminal];

        if (_outputHandleIsATerminal) {
            // Determine the clear-to-EOL character so that there will be no delay while writing the log.
            (void)[[self class] clearToEOLCharacter];

            struct winsize w = {0};
            ioctl(handleDescriptor, TIOCGWINSZ, &w);
            _dividerWidth = (NSUInteger)w.ws_col;
        }

        _dividerWidth = _dividerWidth ?: kDefaultWidth;

        _indentString = @"";

        _outputFormatter = [[SITerminalStringFormatter alloc] init];
        _outputFormatter.useColors = [[self class] environmentSupportsColors];
        _outputFormatter.useUnicodeCharacters = [[self class] environmentSupportsUnicode];
    }
    return self;
}

- (void)setIndentLevel:(NSUInteger)indentLevel {
    NSAssert(indentLevel != NSUIntegerMax, @"An attempt was made to set the indent level to -1!");

    if (indentLevel != _indentLevel) {
        _indentLevel = indentLevel;
        _indentString = [@"" stringByPaddingToLength:(indentLevel * kIndentSize)
                                          withString:@" " startingAtIndex:0];
    }
}

- (void)setDividerActive:(BOOL)dividerActive {
    if (dividerActive != _dividerActive) {
        // flush output pending before the divider changes state
        if (![self lineHasEnded]) [self printNewline];

        _dividerActive = dividerActive;

        // the bar links back to the indent
        NSUInteger barLocation = [_indentString length];
        // and so faces upward if the divider just became active, downward otherwise
        NSString *divider = [self dividerWithBarAtLocation:barLocation facingUpward:_dividerActive];

        // print the divider directly--it shouldn't be formatted
        [_outputHandle writeData:[divider dataUsingEncoding:NSUTF8StringEncoding]];
        [self printNewline];
    }
}

- (NSString *)dividerWithBarAtLocation:(NSUInteger)barLocation facingUpward:(BOOL)facingUpward {
    NSString *dashStr, *barStr;
    if (_outputHandleIsATerminal && [[self class] environmentSupportsUnicode]) {
        dashStr = @"\u2500";
        barStr = facingUpward ? @"\u2534" : @"\u252C";
    } else {
        dashStr = @"-";
        barStr = @"|";
    }

    NSString *divider = [@"" stringByPaddingToLength:_dividerWidth withString:dashStr startingAtIndex:0];
    divider = [divider stringByReplacingCharactersInRange:NSMakeRange(barLocation, [barStr length])
                                               withString:barStr];
    return divider;
}

- (BOOL)lineHasEnded {
    // The line has ended unless we've written something ("current") to the line,
    // or we're waiting to write something ("pending") to the line.
    return !(_currentLine || _pendingLine);
}

- (void)printLine:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    [self updateLineWithFormat:format arguments:args];
    va_end(args);

    [self printNewline];
}

- (void)updateLine:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    [self updateLineWithFormat:format arguments:args];
    va_end(args);
}

- (void)updateLineWithFormat:(NSString *)format arguments:(va_list)argList {
    NSString *formattedLine = [[NSString alloc] initWithFormat:format arguments:argList];
    if (self.dividerActive) {
        formattedLine = [NSString stringWithFormat:@"<faint>%@</faint>", formattedLine];
    } else {
        formattedLine = [NSString stringWithFormat:@"%@%@", _indentString, formattedLine];
    }
    formattedLine = [_outputFormatter formattedStringFromString:formattedLine];

    // Unescape entities that were escaped in anticipation of terminal-formatting.
    formattedLine = CFBridgingRelease(CFXMLCreateStringByUnescapingEntities(kCFAllocatorDefault, (__bridge CFStringRef)formattedLine, NULL));

    if (_outputHandleIsATerminal) {
        // The carriage return + clear-to-EOL character will overwrite the current line.
        [_outputHandle printString:@"\r%@", [[self class] clearToEOLCharacter]];
        [_outputHandle printString:@"%@", formattedLine];
        _currentLine = formattedLine;
    } else {
        // Since we can't overwrite the current line, we've got to cache this update
        // so that we can potentially discard it if another update comes in before a newline.
        _pendingLine = formattedLine;
    }
}

- (void)printNewline {
    if (_pendingLine) {
        [_outputHandle printString:@"%@", _pendingLine];
        _pendingLine = nil;
    }
    _currentLine = nil;
    [_outputHandle printString:@"\n"];
}

@end
