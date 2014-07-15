//
//  SLStringUtilities.m
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

#import "SLStringUtilities.h"

@implementation NSString (SLJavaScript)

- (NSString *)slStringByEscapingForJavaScriptLiteral {
    // Escape sequences taken from here: http://www.ecma-international.org/ecma-262/5.1/#sec-7.8.4
    NSString *literal = [self stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    literal = [literal stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    literal = [literal stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
    literal = [literal stringByReplacingOccurrencesOfString:@"\b" withString:@"\\b"];
    literal = [literal stringByReplacingOccurrencesOfString:@"\f" withString:@"\\f"];
    literal = [literal stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    literal = [literal stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    literal = [literal stringByReplacingOccurrencesOfString:@"\t" withString:@"\\t"];
    literal = [literal stringByReplacingOccurrencesOfString:@"\v" withString:@"\\v"];
    return literal;
}

@end


NSString *SLComposeString(NSString *leadingString, NSString *format, ...)
{
    va_list args;
    va_start(args, format);
    NSString *formattedString = SLComposeStringv(leadingString, format, args);
    va_end(args);

    return formattedString;
}

NSString *SLComposeStringv(NSString *leadingString, NSString *format, va_list args) {
    if (!format) {
        return @"";
    }

    NSString *formattedString = [[NSString alloc] initWithFormat:format arguments:args];
    if (leadingString) {
        return [leadingString stringByAppendingString:formattedString];
    }

    return formattedString;
}
