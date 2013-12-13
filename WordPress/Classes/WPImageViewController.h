//
//  WPImageViewController.h
//  WordPress
//
//  Created by Eric J on 5/10/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WPImageViewController : UIViewController

- (id)initWithImage:(UIImage *)image;
- (id)initWithURL:(NSURL *)url;
- (id)initWithImage:(UIImage *)image andURL:(NSURL *)url;

@end
