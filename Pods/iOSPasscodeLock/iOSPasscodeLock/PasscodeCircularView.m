/*
 *  PasscodeCircularView.m
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */


#import "PasscodeCircularView.h"

@interface PasscodeCircularView ()

@property (nonatomic, strong) CAShapeLayer *circle;
@property (nonatomic, strong) UIColor *lineColor;
@property (nonatomic, strong) UIColor *fillColor;

@end

@implementation PasscodeCircularView

- (id)initWithFrame:(CGRect)frame lineColor:(UIColor *) lineColor fillColor:(UIColor *) fillColor {
  
    self = [super initWithFrame:frame];
    if(self) {
        _lineColor = lineColor;
        _fillColor = fillColor;
        _circle =[CAShapeLayer layer];
        [_circle setBounds:CGRectMake(0.0f, 0.0f, [self bounds].size.width, [self bounds].size.height)];
        [_circle setPosition:CGPointMake(CGRectGetMidX([self bounds]),CGRectGetMidY([self bounds]))];
        UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame))];
        [_circle setPath:[path CGPath]];
        [_circle setStrokeColor:self.lineColor.CGColor];
        [_circle setLineWidth:0.5f];
        [_circle setFillColor:[UIColor clearColor].CGColor];
        [[self layer] addSublayer:self.circle];
    }
    return self;
}

- (void)fill {
    [self.circle setFillColor:self.fillColor.CGColor];
}

- (void)clear {
    [self.circle setFillColor:[UIColor clearColor].CGColor];
}


@end
