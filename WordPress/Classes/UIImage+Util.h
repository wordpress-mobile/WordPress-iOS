//
//  UIImage+Util.h
//  WordPress
//
//  Created by Eric Johnson on 2/19/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Util)

+ (UIImage *)imageWithColor:(UIColor *)color;
+ (UIImage *)imageWithColor:(UIColor *)color havingSize:(CGSize)size;

@end
