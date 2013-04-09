//
//  QuickPicturePreviewView.m
//  WordPress
//
//  Created by Jorge Bernal on 4/8/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "QuickPicturePreviewView.h"
#define QPP_MARGIN 5.0f
#define QPP_FRAME_WIDTH 5.0f
#define QPP_SHADOW_SIZE 5.0f
#define MAX_ZOOM_SCALE 3.0f
#define ZOOM_ANIMATION_DURATION 0.3f

@implementation QuickPicturePreviewView

@synthesize delegate, zoomed;

- (void)setupView {
    zoomed = NO;
    zooming = NO;
    hasBorderAndClip = YES;
    
    backgroundView = [[UIView alloc] initWithFrame:self.frame];
    backgroundView.hidden = YES;
    backgroundView.opaque = NO;
    backgroundView.backgroundColor = [UIColor blackColor];
    backgroundView.alpha = 0.0f;

    scrollView = [[UIScrollView alloc] initWithFrame:self.frame];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scrollView.maximumZoomScale = MAX_ZOOM_SCALE;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    scrollView.delegate = self;
    scrollView.hidden = YES;
    scrollView.contentSize = CGSizeMake(1.f,1.f);
    scrollView.scrollEnabled = NO;
    scrollView.bounces = YES;
    scrollView.backgroundColor = [UIColor clearColor];
    [self addSubview:scrollView];
    
    UISwipeGestureRecognizer *swipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(zoomOut)];
    swipeRecognizer.direction = UISwipeGestureRecognizerDirectionUp | UISwipeGestureRecognizerDirectionDown;
    [scrollView addGestureRecognizer:swipeRecognizer];

    UITapGestureRecognizer *zoomOutRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(zoomOut)];
    zoomOutRecognizer.numberOfTapsRequired = 1;
    [scrollView addGestureRecognizer:zoomOutRecognizer];

    UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(zoomIn)];
    doubleTapRecognizer.numberOfTapsRequired = 2;
    [scrollView addGestureRecognizer:doubleTapRecognizer];
    [zoomOutRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
    
    zoomView = [[UIImageView alloc] init];
    zoomView.contentMode = UIViewContentModeScaleAspectFit;
    zoomView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [scrollView addSubview:zoomView];
    
    imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:imageView];
    
    UIInterfaceOrientation statusBarOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UIInterfaceOrientationIsLandscape(statusBarOrientation)) {
        [self setupForOrientation:UIInterfaceOrientationPortraitUpsideDown];
    } else if (statusBarOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        [self setupForOrientation:UIInterfaceOrientationPortrait];
    }
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(zoomIn)];
    tapRecognizer.numberOfTapsRequired = 1;
    [self addGestureRecognizer:tapRecognizer];
}

- (id)init {
    self = [super init];
    if (self) {
        [self setupView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupView];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void) setBorderAndClipShowing:(BOOL)visible {
    hasBorderAndClip = visible;
    [self layoutSubviews];
}

- (void)layoutSubviews {
    UIImage *image = imageView.image;
    if (image != nil) {
        if (!zooming && !zoomed) {
            CGFloat imageRatio = image.size.width / image.size.height;
            CGSize frameSize = self.frame.size;
            if (!hasBorderAndClip)
                imageRatio = frameSize.width / frameSize.height;
            CGRect imageFrame;
            
            CGFloat width, height, maxsize;
            if (frameSize.width > frameSize.height) {
                maxsize = hasBorderAndClip ? frameSize.height : frameSize.width;
            } else {
                maxsize = hasBorderAndClip ? frameSize.width : frameSize.height;
            }
            if (imageRatio > 1) {
                width = hasBorderAndClip ? maxsize - 2.0f * (QPP_MARGIN + QPP_FRAME_WIDTH) : maxsize;
                height = width / imageRatio;
            } else {
                height = hasBorderAndClip ? maxsize - 2.0f * (QPP_MARGIN + QPP_FRAME_WIDTH) : maxsize;
                width = height * imageRatio;
            }
            
            if (hasBorderAndClip) {
                width += 5.0f;
                height += 5.0f;
            }
            
            if (hasBorderAndClip) {
                imageFrame = CGRectMake(
                                        frameSize.width - width - (QPP_MARGIN + QPP_FRAME_WIDTH),
                                        QPP_MARGIN + QPP_FRAME_WIDTH,
                                        width,
                                        height);
            } else {
                imageFrame = CGRectMake(0, 0, width, height);
            }
            
            imageView.frame = imageFrame;
            if (frameLayer == nil) {
                frameLayer = [CALayer layer];
                frameLayer.zPosition = -5;
                // Check for shadow compatibility (iOS 3.2+)
                if ([frameLayer respondsToSelector:@selector(setShadowColor:)]) {
                    frameLayer.shadowColor = [UIColor blackColor].CGColor;
                    frameLayer.shadowOffset = CGSizeMake(0.0f, 0.75f);
                    frameLayer.shadowOpacity = 0.5f;
                    frameLayer.shadowRadius = 1.0f;
                }
                if (hasBorderAndClip) {
                    frameLayer.backgroundColor = [UIColor whiteColor].CGColor;
                    [self.layer addSublayer:frameLayer];
                }
            }
            if (hasBorderAndClip) {
                imageFrame.size.width += 2 * QPP_FRAME_WIDTH;
                imageFrame.size.height += 2 * QPP_FRAME_WIDTH;
                imageFrame.origin.x -= QPP_FRAME_WIDTH;
                imageFrame.origin.y -= QPP_FRAME_WIDTH;
            }
            frameLayer.frame = imageFrame;
            
            if (hasBorderAndClip) {
                paperClipImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"paperclip.png"]];
                paperClipImageView.frame = CGRectMake(3.0f, -8.0f, 15.0f, 41.0f);
                [paperClipImageView setHidden:NO];
                [imageView addSubview:paperClipImageView];
            }
        }
    }
    
    [super layoutSubviews];
}

- (UIImage *)image {
    return imageView.image;
}

- (void)setImage:(UIImage *)image {
    [imageView setImage:image];
    [zoomView setImage:image];
    [self setNeedsLayout];
}

- (void) zoomIn {
    if (zoomed) {
        if (scrollView.zoomScale <= 1.0f)
            [scrollView setZoomScale:2.0f animated:YES];
        else
            [scrollView setZoomScale:1.0f animated:YES];
        return;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(pictureWillZoom)]) {
        [self.delegate pictureWillZoom];
    }
    imageView.hidden = YES;
    frameLayer.opacity = 0.0f;
    zooming = YES;
    
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    
    scrollView.userInteractionEnabled = YES;
    scrollView.scrollEnabled = YES;
    scrollView.hidden = backgroundView.hidden = NO;
    backgroundView.frame = [UIScreen mainScreen].bounds;
    [window addSubview:backgroundView];

    UIInterfaceOrientation current = [[UIApplication sharedApplication] statusBarOrientation];
    CGSize size = [UIScreen mainScreen].bounds.size;
    if (UIInterfaceOrientationIsLandscape(current)) {
        size = CGSizeMake(size.height, size.width);
    }
    scrollView.contentSize = size;
    if (hasBorderAndClip) {
        scrollView.frame = [self convertRect:imageView.frame toView:window];
    } else {
        scrollView.frame = [self convertRect:imageView.bounds toView:window];
    }
    originalFrame = scrollView.frame;
    zoomView.bounds = [self convertRect:imageView.bounds toView:scrollView];
    zoomView.frame = CGRectMake(0, 0, scrollView.bounds.size.width, scrollView.bounds.size.height);
    [window addSubview:scrollView];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];

    [UIView animateWithDuration:ZOOM_ANIMATION_DURATION
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         scrollView.frame = [UIScreen mainScreen].bounds;
                         backgroundView.alpha = 1.0f;
                         if (hasBorderAndClip)
                             paperClipImageView.alpha = 0.0f;
                     } completion:^(BOOL finished) {
                         zooming = NO;
                         zoomed = YES;
                         if (self.delegate && [self.delegate respondsToSelector:@selector(pictureDidZoom)])
                             [self.delegate pictureDidZoom];
                     }];
}

- (void) zoomOut {
    if (self.delegate && [self.delegate respondsToSelector:@selector(pictureWillRestore)]) {
        [self.delegate pictureWillRestore];
    }
    zooming = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        double delayInSeconds = 0.0;
        if (scrollView.zoomScale > 1) {
            [scrollView setZoomScale:1.f animated:YES];
            delayInSeconds = 0.3;
        }
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            scrollView.userInteractionEnabled = NO;
            scrollView.scrollEnabled = NO;
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
            
            [UIView animateWithDuration:ZOOM_ANIMATION_DURATION
                                  delay:0.0f
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 scrollView.zoomScale = 1.0;
                                 backgroundView.alpha = 0.0f;
                                 scrollView.frame = originalFrame;
                                 if (hasBorderAndClip)
                                     paperClipImageView.alpha = 1.0f;
                             } completion:^(BOOL finished) {
                                 [scrollView removeFromSuperview];
                                 [backgroundView removeFromSuperview];
                                 zooming = NO;
                                 zoomed = NO;
                                 imageView.hidden = NO;
                                 frameLayer.opacity = 1.0f;
                                 if (self.delegate && [self.delegate respondsToSelector:@selector(pictureDidRestore)])
                                     [self.delegate pictureDidRestore];
                             }];
        });
    });
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return zoomView;
}

- (void)scrollViewDidZoom:(UIScrollView *)_scrollView {
    if (_scrollView.zoomScale > 1.f) {
        _scrollView.scrollEnabled = YES;
    } else {
        _scrollView.scrollEnabled = NO;
    }

    if (!_scrollView.zooming && _scrollView.zoomBouncing && _scrollView.zoomScale <= 1.f) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self zoomOut];
        });
    }
}

- (void) setupForOrientation:(UIInterfaceOrientation)orientation {
    UIInterfaceOrientation current = [[UIApplication sharedApplication] statusBarOrientation];
    
	CGFloat angle = 0.0;
	switch (current) {
		case UIInterfaceOrientationPortrait: {
			switch (orientation) {
				case UIInterfaceOrientationPortraitUpsideDown:
					angle = (CGFloat)M_PI;
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
					angle = (CGFloat)M_PI;
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
					angle = (CGFloat)M_PI;
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
					angle = (CGFloat)M_PI;
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
        scrollView.transform = CGAffineTransformConcat(rotation, scrollView.transform);
    }];
}

- (void)orientationWillChange:(NSNotification *)note {
    UIInterfaceOrientation orientation = [[[note userInfo] objectForKey: UIApplicationStatusBarOrientationUserInfoKey] integerValue];
    if (scrollView) {
        if (zoomed) {
            [scrollView setZoomScale:1.f animated:YES];
        }
        [self setupForOrientation:orientation];
    }
}

- (void)orientationDidChange:(NSNotification *)note {
    if (zoomed && scrollView) {
        UIWindow *window = [[UIApplication sharedApplication] keyWindow];
        if (hasBorderAndClip) {
            originalFrame = [self convertRect:imageView.frame toView:window];
        } else {
            originalFrame = [self convertRect:self.bounds toView:window];
        }
        imageView.frame = self.bounds;
        scrollView.frame = [UIScreen mainScreen].bounds;
    }
}

@end
