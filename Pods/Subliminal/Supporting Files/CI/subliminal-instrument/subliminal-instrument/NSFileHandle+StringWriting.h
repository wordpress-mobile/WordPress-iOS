//
//  NSFileHandle+StringWriting.h
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
 The `NSFileHandle (StringWriting)` category defines a convenience method
 for writing strings to file handles.
 */
@interface NSFileHandle (StringWriting)

/**
 Writes the UTF8-encoded representation of the format string to the receiver.
 
 @param format A format string. This value must not be `nil`.
 @param ... A comma-separated list of arguments to substitute into format.
 */
- (void)printString:(NSString *)format, ... NS_FORMAT_FUNCTION(1, 2);

@end
