//
//  WPKeyboardToolbar.m
//  WordPress
//
//  Created by Jorge Bernal on 8/11/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import "WPKeyboardToolbar.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#define CGColorFromRGB(rgbValue) UIColorFromRGB(rgbValue).CGColor

#pragma mark - Constants

#define kStartColor UIColorFromRGB(0xb0b7c1)
#define kEndColor UIColorFromRGB(0x9199a4)
#define kStartColorIpad UIColorFromRGB(0xb7b6bf)
#define kEndColorIpad UIColorFromRGB(0x9d9ca7)

#pragma mark Sizes

// Spacing between button groups
#define WPKT_BUTTON_SEPARATOR 6.0f

#define WPKT_BUTTON_HEIGHT_PORTRAIT 39.0f
#define WPKT_BUTTON_HEIGHT_LANDSCAPE 34.0f
#define WPKT_BUTTON_HEIGHT_IPAD 65.0f

// Button Width is icon width + padding
#define WPKT_BUTTON_PADDING_IPAD 18.0f
#define WPKT_BUTTON_PADDING_IPHONE 10.0f

// Button margin
#define WPKT_BUTTON_MARGIN_IPHONE 4.0f
#define WPKT_BUTTON_MARGIN_IPAD 0.0f

#pragma mark -

@implementation WPKeyboardToolbar

- (CGRect)gradientFrame {
    CGRect rect = self.bounds;
    rect.origin.y += 2;
    rect.size.height -= 2;
    return rect;
}

- (void)drawTopBorder {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 1.0f);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    if (IS_IPAD) {
        CGContextSetStrokeColorWithColor(context, CGColorFromRGB(0x404040));
    } else {
        CGContextSetStrokeColorWithColor(context, CGColorFromRGB(0x52555b));        
    }
    CGContextMoveToPoint(context, self.bounds.origin.x, self.bounds.origin.y + 0.5f);
    CGContextAddLineToPoint(context, self.bounds.size.width, self.bounds.origin.y + 0.5f);
    CGContextStrokePath(context);
    if (IS_IPAD) {
        CGContextSetStrokeColorWithColor(context, CGColorFromRGB(0xd9d9d9));
    } else {
        CGContextSetStrokeColorWithColor(context, CGColorFromRGB(0xdbdfe4));
    }
    CGContextMoveToPoint(context, self.bounds.origin.x, self.bounds.origin.y + 1.5f);
    CGContextAddLineToPoint(context, self.bounds.size.width, self.bounds.origin.y + 1.5f);
    CGContextStrokePath(context);
    CGColorSpaceRelease(colorspace);
}

- (void)drawRect:(CGRect)rect {
    [self drawTopBorder];
}

- (void)setupView {
    _gradient = [CAGradientLayer layer];
    _gradient.frame = [self gradientFrame];
    self.backgroundColor = UIColorFromRGB(0xb0b7c1);
    if (IS_IPAD) {
        _gradient.colors = [NSArray arrayWithObjects:(id)kStartColorIpad.CGColor, (id)kEndColorIpad.CGColor, nil];
    } else {
        _gradient.colors = [NSArray arrayWithObjects:(id)kStartColor.CGColor, (id)kEndColor.CGColor, nil];
    }
    [self.layer insertSublayer:_gradient atIndex:0];
    self.backgroundColor = UIColorFromRGB(0xb0b7c1);
    [super setupView];
}

- (void)layoutSubviews {
    _gradient.frame = [self gradientFrame];
    [super layoutSubviews];
}

@end
