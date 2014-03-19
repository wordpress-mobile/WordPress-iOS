/*
 * Author: Landon Fuller <landonf@plausiblelabs.com>
 *
 * Copyright (c) 2008-2012 Plausible Labs Cooperative, Inc.
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

@interface PLCrashReportApplicationInfo : NSObject {
@private
    /** Application identifier */
    NSString *_applicationIdentifier;
    
    /** Application version */
    NSString *_applicationVersion;
  
    /** Application short version */
    NSString *_applicationShortVersion;
  
    /** Application startup timestamp */
    NSDate *_applicationStartupTimestamp;
}

- (id) initWithApplicationIdentifier: (NSString *) applicationIdentifier 
                  applicationVersion: (NSString *) applicationVersion
             applicationShortVersion: (NSString *) applicationShortVersion
         applicationStartupTimestamp: (NSDate *) applicationStartupTimestamp;

/**
 * The application identifier. This is usually the application's CFBundleIdentifier value.
 */
@property(nonatomic, readonly) NSString *applicationIdentifier;

/**
 * The application version. This is usually the application's CFBundleVersion value.
 */
@property(nonatomic, readonly) NSString *applicationVersion;

/**
 * The application short version. This is usually the application's CFBundleShortVersionString value.
 */
@property(nonatomic, readonly) NSString *applicationShortVersion;

/**
 * The application startup timestamp. This is set when initializing the crash reporter.
 */
@property(nonatomic, readonly) NSDate *applicationStartupTimestamp;

@end
