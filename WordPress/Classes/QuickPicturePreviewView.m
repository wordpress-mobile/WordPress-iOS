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

@implementation QuickPicturePreviewView

@synthesize delegate;

- (void)setupView {
    zoomed = NO;
    zooming = NO;
    hasPaperClip = YES;
    hasPictureFrame = YES;
    
    scrollView = [[UIScrollView alloc] initWithFrame:self.frame];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scrollView.maximumZoomScale = 2.0f;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    scrollView.delegate = self;
    scrollView.hidden = YES;
    scrollView.contentSize = CGSizeMake(1.f,1.f);
    scrollView.scrollEnabled = NO;
    [self addSubview:scrollView];
    
    zoomView = [[UIImageView alloc] init];
    zoomView.contentMode = UIViewContentModeScaleAspectFit;
    zoomView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [scrollView addSubview:zoomView];
    
    imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:imageView];
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

- (void) setPaperClipShowing:(BOOL)visible {
    hasPaperClip = visible;
    [self layoutSubviews];
}

- (void) setPictureFrameShowing:(BOOL)visible {
    hasPictureFrame = visible;
    [self layoutSubviews];
}


- (void)layoutSubviews {
    UIImage *image = imageView.image;
    if (image != nil) {
        if (!zooming && !zoomed) {
            CGSize imageSize = image.size;
            CGFloat imageRatio = imageSize.width / imageSize.height;
            CGSize frameSize = self.frame.size;
            CGRect imageFrame;

            CGFloat width, height, maxsize;
            if (frameSize.width > frameSize.height) {
                // TODO: use another bool
                maxsize = hasPictureFrame ? frameSize.height : frameSize.width;
            } else {
                maxsize = hasPictureFrame ? frameSize.width : frameSize.height;
            }
            if (imageRatio > 1) {
                width = hasPictureFrame ? maxsize - 2.0f * (QPP_MARGIN + QPP_FRAME_WIDTH) : maxsize;
                height = width / imageRatio;
            } else {
                height = hasPictureFrame ? maxsize - 2.0f * (QPP_MARGIN + QPP_FRAME_WIDTH) : maxsize;
                width = height * imageRatio;
            }
            
            if (hasPictureFrame) {
                width += 5.0f;
                height += 5.0f;
            }
            
            if (hasPictureFrame) {
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
                frameLayer.backgroundColor = [UIColor whiteColor].CGColor;
                frameLayer.zPosition = -5;
                // Check for shadow compatibility (iOS 3.2+)
                if ([frameLayer respondsToSelector:@selector(setShadowColor:)]) {
                    frameLayer.shadowColor = [UIColor blackColor].CGColor;
                    frameLayer.shadowOffset = CGSizeMake(0.0f, 0.75f);
                    frameLayer.shadowOpacity = 0.5f;
                    frameLayer.shadowRadius = 1.0f;
                }
                [self.layer addSublayer:frameLayer];
            }
            if (hasPictureFrame) {
                imageFrame.size.width += 2 * QPP_FRAME_WIDTH;
                imageFrame.size.height += 2 * QPP_FRAME_WIDTH;
                imageFrame.origin.x -= QPP_FRAME_WIDTH;
                imageFrame.origin.y -= QPP_FRAME_WIDTH;
            }
            frameLayer.frame = imageFrame;
            
            if (hasPaperClip) {
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
    if (self.delegate && [self.delegate respondsToSelector:@selector(pictureWillZoom)]) {
        [self.delegate pictureWillZoom];
    }
    imageView.hidden = YES;
    frameLayer.opacity = 0.0f;
    CGFloat barHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    scrollView.userInteractionEnabled = YES;
    scrollView.contentSize = window.bounds.size;
    scrollView.hidden = NO;
    scrollView.frame = [self convertRect:imageView.frame toView:window];
    originalFrame = scrollView.frame;
    scrollView.scrollEnabled = YES;
    zoomView.bounds = [self convertRect:imageView.bounds toView:scrollView];
    zoomView.frame = CGRectMake(0, 0, scrollView.frame.size.width, scrollView.frame.size.height);
    [window addSubview:scrollView];
    
    [UIView animateWithDuration:0.4f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         scrollView.backgroundColor = [UIColor blackColor];
                         scrollView.frame = CGRectOffset(window.frame, 0, barHeight);
                         if (hasPaperClip)
                             paperClipImageView.alpha = 0.0f;
                     } completion:^(BOOL finished) {
                         zooming = NO;
                         if (!zoomed) {
                             frameLayer.opacity = 1.0f;
                         }
                         if (self.delegate && [self.delegate respondsToSelector:@selector(pictureDidZoom)])
                             [self.delegate pictureDidZoom];
                     }];
}

- (void) zoomOut {
    if (self.delegate && [self.delegate respondsToSelector:@selector(pictureWillRestore)]) {
        [self.delegate pictureWillRestore];
    }
    scrollView.userInteractionEnabled = NO;
    
    [UIView animateWithDuration:0.4f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         scrollView.backgroundColor = [UIColor clearColor];
                         scrollView.frame = originalFrame;
                         if (hasPaperClip)
                             paperClipImageView.alpha = 1.0f;
                     } completion:^(BOOL finished) {
                         [scrollView removeFromSuperview];
                         zooming = NO;
                         imageView.hidden = NO;
                         frameLayer.opacity = 1.0f;
                         if (self.delegate && [self.delegate respondsToSelector:@selector(pictureDidRestore)])
                             [self.delegate pictureDidRestore];
                     }];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    NSUInteger numTaps = [touch tapCount];
    
    if (numTaps == 1) {
        zooming = YES;
        zoomed = ! zoomed;
        if (zoomed) {
            [self zoomIn];
        } else {
            [self zoomOut];
        }
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return zoomView;
}

- (void)scrollViewDidZoom:(UIScrollView *)_scrollView {
    // if we zoomed in we want to allow panning around
    if (_scrollView.zoomScale > 1.f) {
        _scrollView.scrollEnabled = YES;
    } else {
        _scrollView.scrollEnabled = NO;
    }
    
    //if (self.zoomGestures & ZoomableGesturePinch) {
    if (!_scrollView.zooming && _scrollView.zoomBouncing && _scrollView.zoomScale <= 1.f) {
        dispatch_async(dispatch_get_main_queue(), ^{
            zoomed = ! zoomed;
            [self zoomOut];
        });
    }
    //    }

}
@end
