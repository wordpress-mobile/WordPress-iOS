//
//  WPImageViewController.h
//  WordPress
//
//  Created by Eric J on 5/10/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WPImageViewController : UIViewController

+ (id)presentAsModalWithImage:(UIImage *)image;
+ (id)presentAsModalWithURL:(NSURL *)url;
+ (id)presentAsModalWithImage:(UIImage *)image andURL:(NSURL *)url;

- (id)initWithImage:(UIImage *)image;
- (id)initWithURL:(NSURL *)url;
- (id)initWithImage:(UIImage *)image andURL:(NSURL *)url;

@end
