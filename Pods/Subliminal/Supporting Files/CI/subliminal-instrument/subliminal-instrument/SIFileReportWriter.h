//
//  SIFileReportWriter.h
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
 Instances of `SIFileReportWriter` (report writers) are used by instances of
 `SITerminalReporter` to write report output to files.
 */
@interface SIFileReportWriter : NSObject

#pragma mark - Configuring a Report Writer
/// ------------------------------------------
/// @name Configuring a Report Writer
/// ------------------------------------------

/**
 The number of indents to use when printing output.
 
 Defaults to 0.
 */
@property (nonatomic) NSUInteger indentLevel;

/**
 Changing this property causes the receiver to print a divider line.
 
 This property defaults to `NO`, such that a divider is considered to be "active"
 if a corresponding "closing" divider has not been been printed.
 */
@property (nonatomic) BOOL dividerActive;

#pragma mark - Initializing a Report Writer
/// ------------------------------------------
/// @name Initializing a Report Writer
/// ------------------------------------------

/**
 Initializes a newly allocated report writer object to write output
 to the specified handle.
 
 @param outputHandle The file handle to which to write output.
 
 @return An initialized report writer object.
 */
- (instancetype)initWithOutputHandle:(NSFileHandle *)outputHandle;

#pragma mark - Writing Output
/// ------------------------------------------
/// @name Writing Output
/// ------------------------------------------

/**
 Prints text to the receiver's output handle _without_ a newline.
 
 The current line of text may be overwritten by calling `-updateLine:` or
 `-printLine:`.
 
 The text will be formatted as determined by the report writer's configuration.
 The text may also contain terminal-formatting markup (see `SITerminalStringFormatter`),
 which will be rendered as appropriate given the capabilities of the output handle.

 @warning Any XML entities in the text that are not part of terminal-formatting markup
          must be escaped using `CFXMLCreateStringByEscapingEntities`. The text
          will be unescaped, using `CFXMLCreateStringByUnescapingEntities`, after
          terminal-formatting markup has been processed.

 @param line A format string. This value must not be `nil`.
 @param ... A comma-separated list of arguments to substitute into _line_.
 
 @see `-printNewline`
 */
- (void)updateLine:(NSString *)line, ... NS_FORMAT_FUNCTION(1, 2);

/**
 Prints a newline to the receiver's output handle.
 
 This may be used to "finalize" a line that was being [updated](-updateLine:).
 */
- (void)printNewline;

/**
 Prints text to the receiver's output handle, followed by a newline.
 
 The text will be formatted as determined by the report writer's configuration.
 The text may also contain terminal-formatting markup (see `SITerminalStringFormatter`),
 which will be rendered as appropriate given the capabilities of the output handle.

 @warning Any XML entities in the text that are not part of terminal-formatting markup
          must be escaped using `CFXMLCreateStringByEscapingEntities`. The text
          will be unescaped, using `CFXMLCreateStringByUnescapingEntities`, after
          terminal-formatting markup has been processed.

 @param line A format string. This value must not be `nil`.
 @param ... A comma-separated list of arguments to substitute into _line_.
 */
- (void)printLine:(NSString *)line, ... NS_FORMAT_FUNCTION(1, 2);

@end
