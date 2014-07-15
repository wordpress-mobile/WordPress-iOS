//
//  NSTask+Utilities.m
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

#import "NSTask+Utilities.h"

#import <util.h>

#import "NSPipe+Utilities.h"

void SIOpenPipeOrPTY(NSFileHandle **readHandle, NSFileHandle **writeHandle, BOOL usePseudoTerminal) {
    NSCAssert(readHandle && writeHandle, @"_readHandle_ and _writeHandle_ are required parameters.");

    if (usePseudoTerminal) {
        int masterFD, slaveFD;
        NSCAssert(openpty(&masterFD, &slaveFD, NULL, NULL, NULL) == 0,
                  @"A pseudoterminal couldn't be opened.");
        *readHandle = [[NSFileHandle alloc] initWithFileDescriptor:masterFD closeOnDealloc:YES];
        *writeHandle = [[NSFileHandle alloc] initWithFileDescriptor:slaveFD closeOnDealloc:YES];
    } else {
        NSPipe *outputPipe = [NSPipe pipe];
        *readHandle = [outputPipe fileHandleForReading];
        *writeHandle = [outputPipe fileHandleForWriting];
    }
}

void SIRegisterHandlerForLinesReadFromHandle(NSFileHandle *handle, void(^lineHandler)(NSString *)) {
    NSCAssert(handle && lineHandler, @"_handle_ and _lineHandler_ are required parameters.");

    // create a buffer to store data until a full line is read
    // the readability handler will retain the buffer
    NSMutableString *buffer = [[NSMutableString alloc] init];

    [handle setReadabilityHandler:^(NSFileHandle *handle) {
        @autoreleasepool {
            NSString *currentText = [[NSString alloc] initWithData:[handle availableData] encoding:NSUTF8StringEncoding];
            [buffer appendString:currentText];

            NSScanner *newlineScanner = [[NSScanner alloc] initWithString:buffer];
            newlineScanner.charactersToBeSkipped = nil; // the scanner would normally skip newlines
            NSUInteger scanOffset = 0;
            NSString *line = nil;
            while ([newlineScanner scanUpToString:@"\n" intoString:&line] &&
                   ![newlineScanner isAtEnd]) { // we found a newline rather than scanning to EOL
                lineHandler(line);
                [newlineScanner scanString:@"\n" intoString:NULL];
                scanOffset = [newlineScanner scanLocation];
            }

            [buffer replaceCharactersInRange:NSMakeRange(0, scanOffset) withString:@""];
        }
    }];
}

@implementation NSTask (Utilities)

+ (NSTask *)watchdogTaskForTask:(NSTask *)task {
    static const NSTimeInterval kDefaultWatchInterval = 1.0;

    NSAssert([task.launchPath length],
             @"The launch path of the task to be watched must be set (and the task otherwise configured) before a watchdog task can be created.");

    NSString *childLaunchPath = task.launchPath;
    NSMutableArray *arguments = [[NSMutableArray alloc] initWithArray:task.arguments];

    int parentPID = [[NSProcessInfo processInfo] processIdentifier];
    [arguments insertObject:[NSString stringWithFormat:@"%i", parentPID] atIndex:0];
    [arguments insertObject:[NSString stringWithFormat:@"%f", kDefaultWatchInterval] atIndex:1];
    [arguments insertObject:childLaunchPath atIndex:2];

    static NSString *__watchdogPath = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __watchdogPath = [[NSBundle mainBundle] pathForResource:@"watchdog" ofType:@"sh"];
    });
    NSAssert([__watchdogPath length],
             @"`watchdog.sh` not found in the directory where `subliminal-instrument` is located.");

    NSTask *watchedTask = [[NSTask alloc] init];
    watchedTask.launchPath = __watchdogPath;
    watchedTask.arguments = arguments;
    watchedTask.currentDirectoryPath =  task.currentDirectoryPath;
    watchedTask.standardError =         task.standardError;
    watchedTask.standardInput =         task.standardInput;
    watchedTask.standardOutput =        task.standardOutput;

    // `-[NSTask environment]` defaults to `nil` but can't be set to `nil`
    if (task.environment) watchedTask.environment = task.environment;

    return watchedTask;
}

- (NSString *)output {
    NSPipe *outPipe = [NSPipe pipe];

    [outPipe beginReadingInBackground];
    [self setStandardOutput:outPipe];

    [self launch];
    [self waitUntilExit];
    [outPipe finishReading];

    // We read in the background, rather than simply doing
    // `NSData *outData = [[outPipe fileHandleForReading] readDataToEndOfFile];`,
    // to avoid the pipe potentially filling up.
    NSData *outData = [outPipe availableData];
    return [[NSString alloc] initWithData:outData encoding:NSUTF8StringEncoding];
}

- (void)launchWithOutputHandler:(void (^)(NSString *))outputHandler errorHandler:(void (^)(NSString *))errorHandler {
    [self launchUsingPseudoTerminal:NO outputHandler:outputHandler errorHandler:errorHandler];
}

- (void)launchUsingPseudoTerminal:(BOOL)usePseudoTerminal
                    outputHandler:(void (^)(NSString *))outputHandler errorHandler:(void (^)(NSString *))errorHandler {
    NSParameterAssert(outputHandler);

    NSFileHandle *outputReadHandle = nil, *outputWriteHandle = nil;
    SIOpenPipeOrPTY(&outputReadHandle, &outputWriteHandle, usePseudoTerminal);
    SIRegisterHandlerForLinesReadFromHandle(outputReadHandle, outputHandler);
    [self setStandardOutput:outputWriteHandle];

    // declaring these handles at the top-level scope causes them to stay alive till the task exits
    NSFileHandle *errorReadHandle = nil, *errorWriteHandle = nil;
    if (errorHandler) {
        SIOpenPipeOrPTY(&errorReadHandle, &errorWriteHandle, usePseudoTerminal);
        SIRegisterHandlerForLinesReadFromHandle(errorReadHandle, errorHandler);
        [self setStandardError:errorWriteHandle];
    }

    [self launch];
    [self waitUntilExit];
}

@end
