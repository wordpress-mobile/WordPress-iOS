//
//  SIOptions.h
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
 Instances of `SIOptions` encapsulate the process of parsing the arguments to
 the `subliminal-instrument` executable.
 
 To use `SIOptions`, allocate an instance and call `-parseArguments:error:`.
 See that method for more information.
 
 To determine what arguments the executable takes, print `+usagePattern`
 and `+optionDescriptions`.
 */
@interface SIOptions : NSObject

#pragma mark - Querying the Parsed Arguments
/// ------------------------------------------
/// @name Parsed Arguments
/// ------------------------------------------

/**
 Determines whether or not to show a help message.
 
 Defaults to `NO`.
 */
@property (nonatomic, readonly) BOOL showHelp;

/**
 The reporters that the `subliminal-instrument` will use to format its output.
 
 The members of this array are instances of `SIReporter`.
 
 Defaults to a single argument, a instance of `SITerminalReporter`.
 Currently not configurable.
 */
@property (nonatomic, readonly) NSArray *reporters;

/**
 The arguments to pass to the `instruments` executable when launched
 by the `subliminal-instrument` executable.
 
 Defaults to `nil`.
 */
@property (nonatomic, readonly) NSArray *instrumentsArguments;

#pragma mark - Querying Usage Information
/// ------------------------------------------
/// @name Querying Usage Information
/// ------------------------------------------

/**
 A string describing the overall manner in which options may be passed to
 the `subliminal-instrument` executable.
 
 This string would be suitable for printing after "usage: subliminal-instrument".
 
 @return    A string describing the overall manner in which options may be passed to
            the `subliminal-instrument` executable.
 */
+ (NSString *)usagePattern;

/**
 A string containing one more more newline-separated descriptions of the arguments
 that the `subliminal-instrument` executable takes.
 
 @return    A string containing one more more newline-separated descriptions
            of the arguments that the `subliminal-instrument` executable takes.
 */
+ (NSString *)optionDescriptions;

#pragma mark - Parsing Arguments
/// ------------------------------------------
/// @name Parsing Arguments
/// ------------------------------------------

/**
 Parses the arguments to the `subliminal-instrument` executable
 and populates the properties in the "Parsed Arguments" section of this interface.
 
 @param arguments   The arguments to the `subliminal-instrument` executable
                    except for the first (the path to the executable).
 @param error   On input, a pointer to an error object or `nil`. If an error occurs
                during parsing and this pointer is non-`nil`, this pointer is set
                to an object containing the error information.
 
 @return `YES` if the arguments were successfully parsed or `NO` if an error ocucrred.
 */
- (BOOL)parseArguments:(NSArray *)arguments error:(NSError *__autoreleasing *)error;

@end
