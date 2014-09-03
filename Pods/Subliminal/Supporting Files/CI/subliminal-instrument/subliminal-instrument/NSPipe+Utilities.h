//
//  NSPipe+Utilities.h
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
 The `NSPipe (Utilities)` category defines convenience methods
 for using instances of `NSPipe`.
 */
@interface NSPipe (Utilities)

/**
 The data read from the receiver.
 
 @see -beginReadingInBackground
 @see -finishReading
 */
@property (nonatomic, strong, readonly) NSData *availableData;

/**
 Reads from the receiver's [read file handle](-fileHandleForReading) in the background.
 
 When the receiver's [write file handle](-fileHandleForWriting) receives
 an end-of-data signal, or `-finishReading` is called, `availableData` will be
 populated with the data that was read.

 You must call this method from a thread that has an active run loop.
 
 @see -finishReading
 */
- (void)beginReadingInBackground;

/**
 Signals end-of-data on the receiver's [write file handle](-fileHandleForWriting)
 if that handle is still open, and blocks until all available data is read.
 
 This is a no-op if the receiver's write file handle is closed or if the receiver
 had never been directed to begin reading.
 
 If the receiver is still reading data, this method will close the receiver's
 write file handle and run the current thread’s `CFRunLoop` object in its default
 mode until the receiver finishes reading data.

 @see -beginReadingInBackground
 */
- (void)finishReading;

@end
