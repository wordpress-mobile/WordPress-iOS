//
//  WPWalkthroughButton.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 4/30/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "WPWalkthroughButton.h"

@implementation WPWalkthroughButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _buttonColor = WPWalkthroughButtonBlue;
        self.backgroundColor = [UIColor clearColor];
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(1, 1);
        self.layer.shadowOpacity = 1.0;
        self.layer.shadowRadius = 0.5;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [self addClippingForRoundedCorners:context];
    [self fillBackground:rect];
    [self drawText:context];
    [self removeClippingForRoundedCorners:context];    
}

- (void)setHighlighted:(BOOL)highlighted
{
    [self setNeedsDisplay];
    [super setHighlighted:highlighted];
}

- (void)setButtonColor:(WPWalkthroughButtonColor)buttonColor
{
    if (_buttonColor != buttonColor) {
        _buttonColor = buttonColor;
        [self setNeedsDisplay];
    }
}

- (void)setText:(NSString *)text
{
    if (_text != text) {
        _text = text;
        [self setNeedsDisplay];
    }
}

#pragma mark - Private Methods

- (void)addClippingForRoundedCorners:(CGContextRef)context
{
    CGContextSaveGState(context);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(2, 2)];
    [path addClip];
}

- (void)removeClippingForRoundedCorners:(CGContextRef)context
{
    CGContextRestoreGState(context);
}

- (void)fillBackground:(CGRect)rect
{
    UIColor *backgroundColor;
    if (self.buttonColor == WPWalkthroughButtonBlue) {
        if (self.highlighted) {
            backgroundColor = [UIColor colorWithRed:30.0/255.0 green:140.0/255.0 blue:190.0/255.0 alpha:1.0];
        } else {
            backgroundColor = [UIColor colorWithRed:46.0/255.0 green:162.0/255.0 blue:204.0/255.0 alpha:1.0];
        }
    } else {
        if (self.highlighted) {
            backgroundColor = [UIColor colorWithRed:42.0/255.0 green:42.0/255.0 blue:42.0/255.0 alpha:1.0];
        } else {
            backgroundColor = [UIColor colorWithRed:238.0/255.0 green:238.0/255.0 blue:238.0/255.0 alpha:1.0];
        }        
    }
    [backgroundColor set];
    UIRectFill(rect);
}

- (void)drawText:(CGContextRef)context
{
    UIFont *font = [UIFont fontWithName:@"OpenSans" size:15.0];
    CGFloat textWidth = CGRectGetWidth(self.frame);
    CGFloat actualFontSize;
    CGSize textSize = [self.text sizeWithFont:font minFontSize:8 actualFontSize:&actualFontSize forWidth:textWidth lineBreakMode:UILineBreakModeTailTruncation];
    
    UIFont *adjustedFont = [UIFont fontWithName:@"OpenSans" size:actualFontSize];
    CGSize adjustedSize = [self.text sizeWithFont:adjustedFont forWidth:textWidth lineBreakMode:UILineBreakModeTailTruncation];
    
    // Configure Text Shadow
    UIColor *shadowColor = [self textShadowColor];
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, CGSizeMake(0.5, 0.5), 1.0, shadowColor.CGColor);

    [self configureTextColor];
    
    CGFloat x = (CGRectGetWidth(self.frame) - adjustedSize.width) / 2.0;
    CGFloat y = (CGRectGetHeight(self.frame) - adjustedSize.height) / 2.0;
    [self.text drawAtPoint:CGPointMake(x,y) forWidth:textSize.width withFont:font minFontSize:8 actualFontSize:&actualFontSize lineBreakMode:UILineBreakModeTailTruncation baselineAdjustment:UIBaselineAdjustmentNone];
    
    CGContextRestoreGState(context);
}

- (UIColor *)textShadowColor
{
    if (self.buttonColor == WPWalkthroughButtonBlue) {
        return [UIColor colorWithRed:0 green:115.0/255.0 blue:164.0/255.0 alpha:1.0];
    } else {
        return [UIColor whiteColor];
    }
}

- (void)configureTextColor
{
    if (self.buttonColor == WPWalkthroughButtonBlue) {
        if (self.enabled) {
            if (self.highlighted) {
                [[UIColor colorWithRed:109.0/255.0 green:190.0/255.0 blue:219.0/255.0 alpha:1.0] set];
            } else {
                [[UIColor whiteColor] set];
            }
        } else {
            if (self.highlighted) {
                [[UIColor whiteColor] set];
            } else {
                [[UIColor colorWithRed:109.0/255.0 green:190.0/255.0 blue:219.0/255.0 alpha:1.0] set];
            }
        }
    } else {
        if (self.enabled) {
            if (self.highlighted) {
                [[UIColor whiteColor] set];
            } else {
                [[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.9] set];
            }
        } else {
            if (self.highlighted) {
                [[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.9] set];
            } else {
                [[UIColor colorWithRed:109.0/255.0 green:190.0/255.0 blue:219.0/255.0 alpha:1.0] set];
            }
        }

    }
    
}

@end
