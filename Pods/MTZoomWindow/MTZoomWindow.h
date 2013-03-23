//
//  MTZoomWindow.h
//
//  Created by Matthias Tretter on 8.3.2011.
//  Copyright (c) 2009-2011 Matthias Tretter, @myell0w. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


#import <Foundation/Foundation.h>
#import "UIView+MTZoom.h"

typedef enum {
    MTZoomGestureTap        = 1 << 0,
    MTZoomGestureDoubleTap  = 1 << 1,
    MTZoomGesturePinch      = 1 << 2
} MTZoomGesture;

typedef NSInteger MTZoomGestureMask;


@interface MTZoomWindow : UIWindow <UIScrollViewDelegate>

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, assign) MTZoomGestureMask zoomGestures;
@property (nonatomic, assign) UIViewAnimationOptions animationOptions;
@property (nonatomic, assign) NSTimeInterval animationDuration;
@property (nonatomic, assign) NSTimeInterval animationDelay;
@property (nonatomic, assign) float maximumZoomScale;
@property (nonatomic, strong, readonly) UIView *zoomedView;
@property (nonatomic, readonly, getter = isZoomedIn) BOOL zoomedIn;


+ (MTZoomWindow *)sharedWindow;

- (void)zoomView:(UIView *)view toSize:(CGSize)size;
- (void)zoomOut;

@end