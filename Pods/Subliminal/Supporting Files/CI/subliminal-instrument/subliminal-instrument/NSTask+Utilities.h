//
//  NSTask+Utilities.h
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
 The `NSTask (Utilities)` category defines convenience methods
 for using instances of `NSTask`.
 */
@interface NSTask (Utilities)

/**
 Creates and returns a watchdog task for a task.
 
 A watchdog task is a task whose executable launches the executable of another task,
 then monitors the execution of the current process and the child process (that
 of the other executable). If the current process should die, the watchdog executable
 will terminate the child process and itself.
 
 _task_ must be fully configured before retrieving a watchdog task for _task_,
 so that the watchdog task may inherit its configuration. Changes to _task_'s
 configuration will thereafter be ignored.

 @param task The task to monitor.
 
 @return A new task that will launch _task_'s executable and terminate it
         if the current process should die before _task_'s executable finishes.
 
 @exception If _task_'s [executable](-launchPath) is not set.
 */
+ (NSTask *)watchdogTaskForTask:(NSTask *)task;

/**
 Launches the receiver, blocks until it is finished, and returns its output.
 
 @return The data written by the receiver to `stdout`, formatted as a UTF8-encoded string.
 */
- (NSString *)output;

/**
 Launches the receiver and feeds its executable's output (and optionally error
 messages) as it is written, line-by-line, to the specified handler(s).
 
 This method invokes `-launchUsingPseudoTerminal:outputHandler:errorHandler:`
 with the specified handlers and without using a psuedo-terminal.

 @param outputHandler   A block to be invoked with lines written by the receiver's
                        executable to `stdout`.
 @param errorHandler    A block to be invoked with lines written by the receiver's
                        executable to `stderr`.
 */
- (void)launchWithOutputHandler:(void (^)(NSString *line))outputHandler
                   errorHandler:(void (^)(NSString *line))errorHandler;

/**
 Launches the receiver and feeds its executable's output (and optionally error
 messages) as it is written, line-by-line, to the specified handler(s).

 This method will block until the receiver is finished by polling the current
 run loop using `NSDefaultRunLoopMode`.
 
 A psuedoterminal should be used if the receiver's executable buffers its output
 if it determines that it is being piped to another process. Using a psuedoterminal
 will enable such an executable's output to be processed without buffering.

 @param usePseudoTerminal If `YES`, the receiver's standard output will be set to
                          the slave end of a psuedoterminal. Otherwise, the receiver's
                          standard output will be set to the write end of an `NSPipe` object.
 @param outputHandler   A block to be invoked with lines written by the receiver's
                        executable to `stdout`.
 @param errorHandler    A block to be invoked with lines written by the receiver's
                        executable to `stderr`.åå
 */
- (void)launchUsingPseudoTerminal:(BOOL)usePsuedoTerminal
                    outputHandler:(void (^)(NSString *line))outputHandler
                     errorHandler:(void (^)(NSString *line))errorHandler;

@end
