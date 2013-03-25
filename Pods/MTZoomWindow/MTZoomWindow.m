//
//  MTZoomWindow.m
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
//
// Rotation code based on Alan Quatermains AQSelfRotatingViewController

#import "MTZoomWindow.h"
#import <QuartzCore/QuartzCore.h>


@interface MTZoomWindow () {
    NSMutableSet *_zoomGestureRecognizers;
}

@property (nonatomic, strong, readwrite) UIView *zoomedView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *zoomContentView;
@property (unsafe_unretained, nonatomic, readonly) UIView *zoomSuperview;

@end


@implementation MTZoomWindow

////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle
////////////////////////////////////////////////////////////////////////

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // setup window
        self.windowLevel = UIWindowLevelStatusBar + 2.f;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.backgroundColor = [UIColor clearColor];

        // setup black backgroundView
        _backgroundView = [[UIView alloc] initWithFrame:self.frame];
        _backgroundView.backgroundColor = [UIColor blackColor];
        _backgroundView.alpha = 0.f;
        _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_backgroundView];

        // setup scrollview
        _maximumZoomScale = 2.f;
        _scrollView = [[UIScrollView alloc] initWithFrame:self.frame];
        _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _scrollView.maximumZoomScale = _maximumZoomScale;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        _scrollView.delegate = self;
        _scrollView.hidden = YES;
        _scrollView.contentSize = CGSizeMake(1.f,1.f);
        _scrollView.scrollEnabled = NO;
        [self addSubview:_scrollView];

        _zoomContentView = [[UIView alloc] initWithFrame:self.scrollView.bounds];
        _zoomContentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _zoomContentView.userInteractionEnabled = NO;
        [_scrollView addSubview:_zoomContentView];

        // setup animation properties
        _animationOptions = UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction;
        _animationDuration = 0.4;
        _animationDelay = 0.;

        _zoomGestureRecognizers = [NSMutableSet set];
        // using setter on purpose here
        self.zoomGestures = MTZoomGestureTap | MTZoomGesturePinch;
        
        // iOS 6 Hacks: willChange and didChange won't get called after launching the Application
        UIInterfaceOrientation statusBarOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (UIInterfaceOrientationIsLandscape(statusBarOrientation)) {
            [self setupForOrientation:UIInterfaceOrientationPortraitUpsideDown forceLayout:YES];
        } else if (statusBarOrientation == UIInterfaceOrientationPortraitUpsideDown) {
            [self setupForOrientation:UIInterfaceOrientationPortrait forceLayout:YES];
        }
        self.frame = [UIScreen mainScreen].bounds;

        // register for orientation change notification
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(orientationWillChange:)
                                                     name:UIApplicationWillChangeStatusBarOrientationNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(orientationDidChange:)
                                                     name:UIApplicationDidChangeStatusBarOrientationNotification
                                                   object:nil];
    }

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillChangeStatusBarOrientationNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidChangeStatusBarOrientationNotification
                                                  object:nil];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - MTZoomWindow
////////////////////////////////////////////////////////////////////////

- (void)zoomView:(UIView *)view toSize:(CGSize)size {
    self.zoomedView = view;

    // save frames before zoom operation
	CGRect originalFrameInWindow = [view convertRect:view.bounds toView:self];

    // pre-setup
    self.backgroundView.alpha = 0.f;
    self.hidden = NO;

    // the zoomedView now has another superview and therefore we must change it's frame
	// to still visually appear on the same place like before to the user
    [self.zoomSuperview addSubview:self.zoomedView];
    self.zoomedView.frame = originalFrameInWindow;
    self.zoomedView.autoresizingMask = self.zoomedView.zoomedAutoresizingMask;

    [UIView animateWithDuration:self.animationDuration
                          delay:self.animationDelay
                        options:self.animationOptions
                     animations:^{
                         self.backgroundView.alpha = 1.f;
                         self.zoomedView.frame = CGRectMake((self.bounds.size.width-size.width)/2.f, (self.bounds.size.height-size.height)/2.f,
                                                            size.width, size.height);
                     } completion:^(BOOL finished) {
                         id<MTZoomWindowDelegate> delegate = view.zoomDelegate;

                         if ([delegate respondsToSelector:@selector(zoomWindow:didZoomInView:)]) {
                             [delegate zoomWindow:self didZoomInView:view];
                         }

                         [self.scrollView flashScrollIndicators];
                     }];
}

- (void)zoomOut {
    if (self.zoomedIn) {
        CGRect destinationFrameInWindow = [self.zoomedView.zoomPlaceholderView convertRect:self.zoomedView.zoomPlaceholderView.bounds toView:self];

        // reset zoom-scale of scrollView
        [self.scrollView setZoomScale:1.f animated:YES];

        [UIView animateWithDuration:self.animationDuration
                              delay:self.animationDelay
                            options:self.animationOptions | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.backgroundView.alpha = 0.0f;
                             self.zoomedView.frame = destinationFrameInWindow;
                         } completion:^(BOOL finished) {
                             // reset zoomed view to original position
                             self.zoomedView.frame = self.zoomedView.zoomPlaceholderView.frame;
                             self.zoomedView.autoresizingMask = self.zoomedView.zoomPlaceholderView.autoresizingMask;
                             [self.zoomedView.zoomPlaceholderView.superview insertSubview:self.zoomedView aboveSubview:self.zoomedView.zoomPlaceholderView];
                             [self.zoomedView.zoomPlaceholderView removeFromSuperview];
                             self.zoomedView.zoomPlaceholderView = nil;
                             // hide window
                             self.hidden = YES;

                             id<MTZoomWindowDelegate> delegate = self.zoomedView.zoomDelegate;

                             if ([delegate respondsToSelector:@selector(zoomWindow:didZoomOutView:)]) {
                                 [delegate zoomWindow:self didZoomOutView:self.zoomedView];
                             }

                             self.zoomedView = nil;
                         }];
    }
}



- (UIView *)zoomSuperview {
    if (self.zoomedView.wrapInScrollviewWhenZoomed) {
        self.scrollView.hidden = NO;
        return self.zoomContentView;
    } else {
        self.scrollView.hidden = YES;
        return self;
    }
}

- (BOOL)isZoomedIn {
    return !self.hidden && self.zoomedView != nil;
}

- (void)setZoomGestures:(MTZoomGestureMask)zoomGestures {
    if (zoomGestures != _zoomGestures) {
        _zoomGestures = zoomGestures;

        // remove old gesture recognizers
        for (UIGestureRecognizer *gestureRecognizer in _zoomGestureRecognizers) {
            [self removeGestureRecognizer:gestureRecognizer];
        }
        [_zoomGestureRecognizers removeAllObjects];

        // create new gesture recognizers
        if (zoomGestures & MTZoomGestureTap) {
            UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                                   action:@selector(handleGesture:)];
            [_zoomGestureRecognizers addObject:tapGestureRecognizer];
        }
        if (zoomGestures & MTZoomGestureDoubleTap) {
            UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                                   action:@selector(handleGesture:)];
            tapGestureRecognizer.numberOfTapsRequired = 2;
            [_zoomGestureRecognizers addObject:tapGestureRecognizer];
        }

        // add new gesture recognizers to views
        for (UIGestureRecognizer *gestureRecognizer in _zoomGestureRecognizers) {
            [self addGestureRecognizer:gestureRecognizer];
        }
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UIScrollViewDelegate
////////////////////////////////////////////////////////////////////////

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.zoomContentView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    // if we zoomed in we want to allow panning around
    if (scrollView.zoomScale > 1.f) {
        scrollView.scrollEnabled = YES;
    } else {
        scrollView.scrollEnabled = NO;
    }

    if (self.zoomGestures & MTZoomGesturePinch) {
        if (!scrollView.zooming && scrollView.zoomBouncing && scrollView.zoomScale <= 1.f) {
            [self.zoomedView zoomOut];
        }
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private
////////////////////////////////////////////////////////////////////////

- (void)handleGesture:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateRecognized) {
        [self.zoomedView zoomOut];
    }
}

- (void)setupForOrientation:(UIInterfaceOrientation)orientation forceLayout:(BOOL)forceLayout {
    UIInterfaceOrientation current = [[UIApplication sharedApplication] statusBarOrientation];

    if (!forceLayout) {
        // if ( [self shouldAutorotateToInterfaceOrientation: orientation] == NO )
        //	return;

        if (current == orientation) {
            return;
        }
    }

	// direction and angle
	CGFloat angle = 0.0;
	switch (current) {
		case UIInterfaceOrientationPortrait: {
			switch (orientation) {
				case UIInterfaceOrientationPortraitUpsideDown:
					angle = (CGFloat)M_PI;	// 180.0*M_PI/180.0 == M_PI
					break;

				case UIInterfaceOrientationLandscapeLeft:
					angle = (CGFloat)(M_PI*-90.0)/180.0;
					break;

				case UIInterfaceOrientationLandscapeRight:
					angle = (CGFloat)(M_PI*90.0)/180.0;
					break;

				default:
					return;
			}
			break;
		}

		case UIInterfaceOrientationPortraitUpsideDown: {
			switch (orientation) {
				case UIInterfaceOrientationPortrait:
					angle = (CGFloat)M_PI;	// 180.0*M_PI/180.0 == M_PI
					break;

				case UIInterfaceOrientationLandscapeLeft:
					angle = (CGFloat)(M_PI*90.0)/180.0;
					break;

				case UIInterfaceOrientationLandscapeRight:
					angle = (CGFloat)(M_PI*-90.0)/180.0;
					break;

				default:
					return;
			}
			break;
		}

		case UIInterfaceOrientationLandscapeLeft: {
			switch (orientation) {
				case UIInterfaceOrientationLandscapeRight:
					angle = (CGFloat)M_PI;	// 180.0*M_PI/180.0 == M_PI
					break;

				case UIInterfaceOrientationPortraitUpsideDown:
					angle = (CGFloat)(M_PI*-90.0)/180.0;
					break;

				case UIInterfaceOrientationPortrait:
					angle = (CGFloat)(M_PI*90.0)/180.0;
					break;

				default:
					return;
			}
			break;
		}

		case UIInterfaceOrientationLandscapeRight: {
			switch (orientation) {
				case UIInterfaceOrientationLandscapeLeft:
					angle = (CGFloat)M_PI;	// 180.0*M_PI/180.0 == M_PI
					break;

				case UIInterfaceOrientationPortrait:
					angle = (CGFloat)(M_PI*-90.0)/180.0;
					break;

				case UIInterfaceOrientationPortraitUpsideDown:
					angle = (CGFloat)(M_PI*90.0)/180.0;
					break;

				default:
					return;
			}
			break;
		}
	}

	CGAffineTransform rotation = CGAffineTransformMakeRotation(angle);

    [UIView animateWithDuration:0.4 animations:^{
        self.transform = CGAffineTransformConcat(rotation, self.transform);
    }];
}

- (void)orientationWillChange:(NSNotification *)note {
	UIInterfaceOrientation orientation = [[[note userInfo] objectForKey: UIApplicationStatusBarOrientationUserInfoKey] integerValue];

    [self.scrollView setZoomScale:1.f animated:YES];
    [self setupForOrientation:orientation forceLayout:NO];
}

- (void)orientationDidChange:(NSNotification *)note {
	// UIInterfaceOrientation orientation = [[[note userInfo] objectForKey: UIApplicationStatusBarOrientationUserInfoKey] integerValue];

    //if ([self shouldAutorotateToInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]] == NO)
	//	return;
    
	self.frame = [UIScreen mainScreen].bounds;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Singleton definitons
////////////////////////////////////////////////////////////////////////

static MTZoomWindow *sharedMTZoomWindow = nil;

+ (MTZoomWindow *)sharedWindow {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMTZoomWindow = [[self alloc] initWithFrame:[UIScreen mainScreen].bounds];
    });
    
	return sharedMTZoomWindow;
}

@end
