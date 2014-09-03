//
//  SITerminalStringFormatter.h
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

/**
 Instances of `SITerminalStringFormatter` process text for output to terminals.
 In particular, they convert XML markup to ANSI escape sequences and Unicode
 characters.
 
 For instance, a string reading "<red>red text</red> plain text <warning/>"
 will be formatted as "\033[31mred text\033[0m plain text ⚠"; that string,
 printed to a capable terminal, will appear in color and with the Unicode
 characters intact.
 
 By setting `useColors` to `NO`, a formatter may be directed to strip color
 information from a string i.e. for output to a terminal that does not support colors.

 By setting `useUnicodeCharacters` to `NO`, a formatter may be directed to replace
 the Unicode markup with ASCII equivalents i.e. for output to a terminal that
 does not support colors.

 ### Supported markup

 The XML tags supported by `SITerminalStringFormatter` are as follows.
 
 Colors:
 
 * `b`:         bold text
 * `faint`:     faint text
 * `ul`:        underlined text
 * `red`:       red text
 * `green`:     green text
 * `yellow`:    yellow text
 
 Unicode (ASCII fallbacks follow in parentheses):
 
 * `pass`:      ✓ (~)
 * `warning`:   ⚠ (!)
 * `fail`:      ✗ (X)
 * `vbar`:      │ (|)

 */
@interface SITerminalStringFormatter : NSObject

/**
 If `YES`, XML markup in strings processed by the receiver will be converted
 to ANSI escape sequences as described in the class discussion. If `NO`, such
 markup will be stripped when formatting such that only plain text is output.

 Defaults to `YES`.
 */
@property (nonatomic) BOOL useColors;

/**
 If `YES`, XML markup in strings processed by the receiver will be converted
 to Unicode characters as described in the class discussion. If `NO`, such
 markup will be converted to ASCII equivalents.
 
 Defaults to `YES`.
 */
@property (nonatomic) BOOL useUnicodeCharacters;

/**
 Formats a string according to its markup and the receiver's configuration.
 
 @warning XML entities that are not part of terminal-formatting markup should be
          escaped e.g. by using `CFXMLCreateStringByEscapingEntities`.

 @param string The string to format, optionally containing markup as described
               in the class discussion.
 
 @return The formatted string, or `nil` if an error occurred while parsing _string_.
 */
- (NSString *)formattedStringFromString:(NSString *)string;

@end
