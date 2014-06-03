// AnimatedGIFImageSerialization.h
//
// Copyright (c) 2014 Mattt Thompson (http://mattt.me/)
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

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)

#import <UIKit/UIKit.h>

/**
 
 */
extern __attribute__((overloadable)) UIImage * UIImageWithAnimatedGIFData(NSData *data);

/**
 
 */
extern __attribute__((overloadable)) UIImage * UIImageWithAnimatedGIFData(NSData *data, CGFloat scale, NSTimeInterval duration, NSError * __autoreleasing *error);

#pragma mark -

/**
 
 */
extern __attribute__((overloadable)) NSData * UIImageAnimatedGIFRepresentation(UIImage *image);

/**
 
 */
extern __attribute__((overloadable)) NSData * UIImageAnimatedGIFRepresentation(UIImage *image, NSTimeInterval duration, NSUInteger loopCount, NSError * __autoreleasing *error);

#pragma mark -

/**
 
 */
@interface AnimatedGIFImageSerialization : NSObject

/// @name Creating an Animated GIF

/**

 */
+ (UIImage *)imageWithData:(NSData *)data
                     error:(NSError * __autoreleasing *)error;

/**

 */
+ (UIImage *)imageWithData:(NSData *)data
                     scale:(CGFloat)scale
                  duration:(NSTimeInterval)duration
                     error:(NSError * __autoreleasing *)error;

/// @name Creating Animated Gif Data

/**

 */
+ (NSData *)animatedGIFDataWithImage:(UIImage *)image
                               error:(NSError * __autoreleasing *)error;

/**
 
 */
+ (NSData *)animatedGIFDataWithImage:(UIImage *)image
                            duration:(NSTimeInterval)duration
                           loopCount:(NSUInteger)loopCount
                               error:(NSError * __autoreleasing *)error;

@end

/**
 
 */
extern NSString * const AnimatedGIFImageErrorDomain;
#endif
