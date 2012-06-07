//
//  UIColor+Helpers.m
//  WordPress
//
//  Created by Danilo Ercoli on 07/06/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "UIColor+Helpers.h"

@implementation UIColor (Helpers)

//[UIColor UIColorFromRGBAColorWithRed:10 green:20 blue:30 alpha:0.8]
+(UIColor *)UIColorFromRGBAColorWithRed: (CGFloat)r green:(CGFloat)g blue:(CGFloat)b alpha:(CGFloat)a {
    return [UIColor colorWithRed: r/255.0 green: g/255.0 blue: b/255.0 alpha:a];
}

//[UIColor UIColorFromRGBColorWithRed:10 green:20 blue:30]
+(UIColor *)UIColorFromRGBColorWithRed:(CGFloat)r green:(CGFloat)g blue:(CGFloat)b {
    return [UIColor colorWithRed: r/255.0 green: g/255.0 blue: b/255.0 alpha: 0.5];
}

//[UIColor UIColorFromHex:0xc5c5c5 alpha:0.8];
+(UIColor *)UIColorFromHex:(NSUInteger)rgb alpha:(CGFloat)alpha {
    return [UIColor colorWithRed:((float)((rgb & 0xFF0000) >> 16))/255.0
                          green:((float)((rgb & 0xFF00) >> 8))/255.0
                           blue:((float)(rgb & 0xFF))/255.0
                          alpha:alpha];
}

//[UIColor UIColorFromHex:0xc5c5c5];
+(UIColor *)UIColorFromHex:(NSUInteger)rgb {
    return [UIColor UIColorFromHex:rgb alpha:1.0];
}

@end
