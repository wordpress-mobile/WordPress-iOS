// WPXMLRPCDecoder.h
//
// Copyright (c) 2013 WordPress - http://wordpress.org/
// Based on Eric Czarny's xmlrpc library - https://github.com/eczarny/xmlrpc
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>

extern NSString *const WPXMLRPCFaultErrorDomain;

/**
 `WPXMLRPCEncoder` encodes a XML-RPC response
 */
@interface WPXMLRPCDecoder : NSObject

/**
 Initializes a `WPXMLRPCDecoder` object with the specified response data.

 @param data the data returned by your XML-RPC request

 @return The newly-initialized XML-RPC response
 */
- (id)initWithData:(NSData *)data;

///-----------------------
/// @name Error management
///-----------------------

/**
 Returns YES if the response contains a XML-RPC error
 */
- (BOOL)isFault;

/**
 The XML-RPC error code
 */
- (NSInteger)faultCode;

/**
 The XML-RPC error message
 */
- (NSString *)faultString;

/**
 Returns an error if there was a problem decoding the data, or if it's a XML-RPC error
 */
- (NSError *)error;

///-------------------------------------
/// @name Accessing the decoded response
///-------------------------------------

/**
 The decoded object
 
 Check isFault before trying to do anything with this object.
 */
- (id)object;

@end
