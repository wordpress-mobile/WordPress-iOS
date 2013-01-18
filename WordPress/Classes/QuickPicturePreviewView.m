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

- (void)layoutSubviews {
    UIImage *image = imageView.image;
    if (image != nil) {
        if (!zooming && !zoomed) {
            CGSize imageSize = image.size;
            CGFloat imageRatio = imageSize.width / imageSize.height;
            CGSize frameSize = self.bounds.size;
            CGRect imageFrame;

            CGFloat width, height, maxsize;
            if (frameSize.width > frameSize.height) {
                maxsize = frameSize.height;
            } else {
                maxsize = frameSize.width;
            }
            if (imageRatio > 1) {
                width = maxsize - 2.0f * (QPP_MARGIN + QPP_FRAME_WIDTH);
                height = width / imageRatio;
            } else {
                height = maxsize - 2.0f * (QPP_MARGIN + QPP_FRAME_WIDTH);
                width = height * imageRatio;
            }
            
            width += 5.0f;
            height += 5.0f;
            
            imageFrame = CGRectMake(
                                    frameSize.width - width - (QPP_MARGIN + QPP_FRAME_WIDTH),
                                    QPP_MARGIN + QPP_FRAME_WIDTH,
                                    width,
                                    height
                                    );
            
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
            imageFrame.size.width += 2 * QPP_FRAME_WIDTH;
            imageFrame.size.height += 2 * QPP_FRAME_WIDTH;
            imageFrame.origin.x -= QPP_FRAME_WIDTH;
            imageFrame.origin.y -= QPP_FRAME_WIDTH;
            frameLayer.frame = imageFrame;
            
            paperClipImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"paperclip.png"]];
            paperClipImageView.frame = CGRectMake(3.0f, -8.0f, 15.0f, 41.0f);
            [paperClipImageView setHidden:NO];
            [imageView addSubview:paperClipImageView];
        }
    }
    
    [super layoutSubviews];
}

- (UIImage *)image {
    return imageView.image;
}

- (void)setImage:(UIImage *)image {
    [imageView setImage:image];
    [self setNeedsLayout];
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    zooming = NO;
    if (!zoomed) {
        frameLayer.opacity = 1.0f;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    NSUInteger numTaps = [touch tapCount];
    
    if (numTaps == 1) {
        zooming = YES;
        zoomed = ! zoomed;
        if (zoomed) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(pictureWillZoom)]) {
                [self.delegate pictureWillZoom];
            }
            frameLayer.opacity = 0.0f;
        } else {
            if (self.delegate && [self.delegate respondsToSelector:@selector(pictureWillRestore)]) {
                [self.delegate pictureWillRestore];
            }
        }
        [UIView beginAnimations:@"zoom" context:nil];
        [UIView setAnimationDuration:0.3f];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
        if (zoomed) {
            normalFrame = self.frame;
            normalImageFrame = imageView.frame;
            self.frame = [self.superview bounds];
            self.backgroundColor = [UIColor blackColor];
            imageView.frame = self.frame;
            paperClipImageView.alpha = 0.0f;
        } else {
            self.frame = normalFrame;
            self.backgroundColor = [UIColor clearColor];
            imageView.frame = normalImageFrame;
            paperClipImageView.alpha = 1.0f;
        }
        [UIView commitAnimations];

        if (zoomed) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(pictureDidZoom)])
                [self.delegate pictureDidZoom];
        } else {
            if (self.delegate && [self.delegate respondsToSelector:@selector(pictureDidRestore)])
                [self.delegate pictureDidRestore];
        }
    }
}

@end
