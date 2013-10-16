//
//  UIImage+Tint.h
//
//  Created by Matt Gemmell on 04/07/2010.
//  Copyright 2010 Instinctive Code.
//

#import <UIKit/UIKit.h>

@interface UIImage (MGTint)

- (UIImage *)imageTintedWithColor:(UIColor *)color;
- (UIImage *)imageTintedWithColor:(UIColor *)color fraction:(CGFloat)fraction;

@end
