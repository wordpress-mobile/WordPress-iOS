//
//  SubliminalInstrument.h
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
 The `SubliminalInstrument` class provides a centralized point of control
 for the `subliminal-instrument` executable.
 
 When the executable is launched, its `main` function passes the process' arguments
 to a `SubliminalInstrument` object and calls `-run`. The `SubliminalInstrument`
 object then runs the `instruments` executable with the specified arguments.
 The object's `terminationStatus` is returned as the executable's exit status.
 
 To see the arguments that `SubliminalInstrument` takes, run it with a single
 argument, "--help".
 */
@interface SubliminalInstrument : NSObject

#pragma mark - Instrument Configuration
/// -----------------------------------------------------
/// @name Configuring a `SubliminalInstrument` Object
/// -----------------------------------------------------

/**
 An array of arguments to the receiver.
 
 These should be the arguments to the `subliminal-instrument` executable
 except for the first (the path to the executable).
 */
@property (nonatomic, copy) NSArray *arguments;

/**
 The standard output file used by the receiver.
 
 Standard output is where the receiver sends its output.
 
 Defaults to `+[NSFileHandle fileHandleWithStandardOutput]`.
 */
@property (nonatomic, strong) NSFileHandle *standardOutput;

/**
 The standard error file used by the receiver.
 
 Standard error is where the receiver sends diagnostic messages.
 
 Defaults to `[NSFileHandle fileHandleWithStandardError]`.
 */
@property (nonatomic, strong) NSFileHandle *standardError;

#pragma mark - Querying the Instrument State
/// ------------------------------------------
/// @name Querying the Instrument State
/// ------------------------------------------

/**
 Returns the receiver's exit status.
 
 This is undefined until the receiver has been [run](-run).
 
 After the receiver has been run, this will be `0` if the receiver completed
 successfully or `1` if it did not.
 */
@property (nonatomic, readonly) int terminationStatus;

#pragma mark - Running the Instrument
/// ------------------------------------------
/// @name Running the Instrument
/// ------------------------------------------

/**
 Launches the `instruments` executable with `arguments`
 and sets `terminationStatus` after the executable has exited.
 */
- (void)run;

@end
