/*
 * Author: Landon Fuller <landonf@plausiblelabs.com>
 *
 * Copyright (c) 2008-2009 Plausible Labs Cooperative, Inc.
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

#import <Foundation/Foundation.h>

@interface PLCrashReportStackFrameInfo : NSObject {
@private
    /** Frame instruction pointer. */
    uint64_t _instructionPointer;
    
    /** Symbol start address, if any. */
    uint64_t _symbolStart;
    
    /** Symbol name, if any. */
    NSString *_symbolName;
}

- (id) initWithInstructionPointer: (uint64_t) instructionPointer symbolStart: (uint64_t) symbolStart symbolName: (NSString *) symbolName;

/**
 * Frame's instruction pointer.
 */
@property(nonatomic, readonly) uint64_t instructionPointer;

/**
 * Frame's symbol address, if determined, otherwise 0.
 */
@property(nonatomic, readonly) uint64_t symbolStart;

/** 
 * Frame's symbol name, if determined, otherwise 0.
 */
@property(nonatomic, readonly) NSString *symbolName;

@end


@interface PLCrashReportRegisterInfo : NSObject {
@private
    /** Register name */
    NSString *_registerName;

    /** Register value */
    uint64_t _registerValue;
}

- (id) initWithRegisterName: (NSString *) registerName registerValue: (uint64_t) registerValue;

/**
 * Register name.
 */
@property(nonatomic, readonly) NSString *registerName;

/**
 * Register value.
 */
@property(nonatomic, readonly) uint64_t registerValue;

@end


@interface PLCrashReportThreadInfo : NSObject {
@private
    /** The thread number. Should be unique within a given crash log. */
    NSInteger _threadNumber;

    /** Ordered list of PLCrashReportStackFrame instances */
    NSArray *_stackFrames;

    /** YES if this thread crashed. */
    BOOL _crashed;

    /** List of PLCrashReportRegister instances. Will be empty if _crashed is NO. */
    NSArray *_registers;
}

- (id) initWithThreadNumber: (NSInteger) threadNumber
                stackFrames: (NSArray *) stackFrames
                    crashed: (BOOL) crashed
                  registers: (NSArray *) registers;

/**
 * Application thread number.
 */
@property(nonatomic, readonly) NSInteger threadNumber;

/**
 * Thread backtrace. Provides an array of PLCrashReportStackFrameInfo instances.
 * The array is ordered, last callee to first.
 */
@property(nonatomic, readonly) NSArray *stackFrames;

/**
 * If this thread crashed, set to YES.
 */
@property(nonatomic, readonly) BOOL crashed;

/**
 * State of the general purpose and related registers, as a list of
 * PLCrashReportRegister instances. If this thead did not crash (crashed returns NO),
 * this list will be empty.
 */
@property(nonatomic, readonly) NSArray *registers;

@end
