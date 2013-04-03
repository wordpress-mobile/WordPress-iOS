//
//  QuickPicturePreviewView.h
//  WordPress
//
//  Created by Jorge Bernal on 4/8/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@protocol QuickPicturePreviewViewDelegate <NSObject>
@optional
- (void)pictureWillZoom;
- (void)pictureDidZoom;
- (void)pictureWillRestore;
- (void)pictureDidRestore;

@end

@interface QuickPicturePreviewView : UIView <UIScrollViewDelegate> {
    UIView *backgroundView;
    UIScrollView *scrollView;
    UIImageView *imageView, *paperClipImageView, *zoomView;
    CALayer *frameLayer;
    BOOL zoomed;
    BOOL zooming;
    BOOL hasBorderAndClip;
    CGRect normalFrame, normalImageFrame;
    CGRect originalFrame;
}

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, weak) IBOutlet id<QuickPicturePreviewViewDelegate> delegate;
@property (nonatomic, assign) BOOL zoomed;

- (void) setBorderAndClipShowing:(BOOL)visible;

@end
