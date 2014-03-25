//
//  WPImageViewController.h
//  WordPress
//
//  Created by Eric J on 5/10/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WPImageViewController : UIViewController

@property (nonatomic, strong) NSURL *url;
@property (nonatomic) BOOL isLoadingImage;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImage *image;

- (id)initWithImage:(UIImage *)image;
- (id)initWithURL:(NSURL *)url;
- (id)initWithImage:(UIImage *)image andURL:(NSURL *)url;
- (void)loadImage;
- (void)hideBars:(BOOL)hide animated:(BOOL)animated;
- (void)centerImage;

@end
