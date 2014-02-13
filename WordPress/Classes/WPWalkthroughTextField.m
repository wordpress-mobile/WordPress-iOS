//
//  WPWalkthroughTextField.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 4/30/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPWalkthroughTextField.h"

@interface WPWalkthroughTextField ()
@property (nonatomic, strong) UIImage *leftViewImage;
@end

@implementation WPWalkthroughTextField

- (id)init
{
    self = [super init];
    if (self)
    {
        self.textInsets = UIEdgeInsetsMake(7, 10, 7, 10);
        self.layer.cornerRadius = 1.0;
        self.clipsToBounds = YES;
        self.showTopLineSeparator = NO;
    }
    return self;
}

- (instancetype)initWithLeftViewImage:(UIImage *)image
{
    self = [self init];
    if (self)
    {
        self.leftViewImage = image;
        self.leftView = [[UIImageView alloc] initWithImage:image];
        self.leftViewMode = UITextFieldViewModeAlways;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    
    // draw top border
    
    if (_showTopLineSeparator) {
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(CGRectGetMinX(rect) + _textInsets.left, CGRectGetMinY(rect))];
        [path addLineToPoint:CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect))];
        [path setLineWidth:[[UIScreen mainScreen] scale] / 2.0];
        CGContextAddPath(context, path.CGPath);
        CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:0.87 alpha:1.0].CGColor);
        CGContextStrokePath(context);
    }
}

- (CGRect)calculateTextRectForBounds:(CGRect)bounds {
    
    if (_leftViewImage) {
        
        CGFloat leftViewWidth = _leftViewImage.size.width;
        return CGRectMake(leftViewWidth + 2 * _textInsets.left, _textInsets.top, bounds.size.width - leftViewWidth - 2 * _textInsets.left - _textInsets.right, bounds.size.height - _textInsets.top - _textInsets.bottom);
    } else {
        return CGRectMake(_textInsets.left, _textInsets.top, bounds.size.width - _textInsets.left - _textInsets.right, bounds.size.height - _textInsets.top - _textInsets.bottom);
    }
}

// placeholder position
- (CGRect)textRectForBounds:(CGRect)bounds
{
    return [self calculateTextRectForBounds:bounds];
}

// text position
- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return [self calculateTextRectForBounds:bounds];
}

// left view position
- (CGRect)leftViewRectForBounds:(CGRect)bounds {
    
    if (_leftViewImage) {
        return CGRectMake(_textInsets.left, (CGRectGetHeight(bounds) - _leftViewImage.size.height) / 2.0, _leftViewImage.size.width, _leftViewImage.size.height);
    } else {
        return [super leftViewRectForBounds:bounds];
    }
}

@end
