//
//  UIView+MTZoom.h
//
//  Created by Matthias Tretter on 23.10.2011.
//  Copyright (c) 2009-2011 Matthias Tretter, @myell0w. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


#import <UIKit/UIKit.h>
#import "MTZoomWindowDelegate.h"

@interface UIView (MTZoom)

/** If yes, the view will be put into a scrollview when zoomed in */
@property (nonatomic, assign, getter = isWrappedInScrollviewWhenZoomed) BOOL wrapInScrollviewWhenZoomed;
/** The size of the view when zoomed in */
@property (nonatomic, assign) CGSize zoomedSize;
/** The autoresizing-maks of the view when zoomed in */
@property (nonatomic, assign) UIViewAutoresizing zoomedAutoresizingMask;
/** the view that acts as a placeholder while self is zoomedIn */
@property (nonatomic, retain) UIView *zoomPlaceholderView;
/** The delegate for zooming */
@property (nonatomic, assign) id<MTZoomWindowDelegate> zoomDelegate;
/** Flag that indicates if the view is currently zoomed in */
@property (nonatomic, readonly, getter = isZoomedIn) BOOL zoomedIn; 

- (void)zoomIn;
- (void)zoomOut;
- (void)toggleZoomState;

@end
