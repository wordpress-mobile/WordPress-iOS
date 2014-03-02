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


- (id) initWithFrame:(CGRect)frame
            lineColor:(UIColor *) lineColor
            fillColor:(UIColor *) fillColor
{
    self = [super init];
    
    if(self)
    {
        self.lineColor = lineColor;
        self.fillColor = fillColor;
        self.frame = frame; 
        [self drawCircular];
    }
    return self;
}


- (void)drawCircular
{
    self.circle = [CAShapeLayer layer];
    [self.circle setBounds:CGRectMake(0.0f, 0.0f, [self bounds].size.width, [self bounds].size.height)];
    [self.circle setPosition:CGPointMake(CGRectGetMidX([self bounds]),CGRectGetMidY([self bounds]))];
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame))];
    [self.circle setPath:[path CGPath]];
    [self.circle setStrokeColor:self.lineColor.CGColor];
    [self.circle setLineWidth:0.5f];
    [self.circle setFillColor:[UIColor clearColor].CGColor];
    [[self layer] addSublayer:self.circle];
}

- (void)fill
{
    [self.circle setFillColor:self.fillColor.CGColor];
}

- (void)clear
{
    [self.circle setFillColor:[UIColor clearColor].CGColor];
}


@end
