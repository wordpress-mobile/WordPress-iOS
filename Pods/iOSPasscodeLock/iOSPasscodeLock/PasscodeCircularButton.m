/*
 *  PasscodeCircularButton.m
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "PasscodeCircularButton.h"

@interface PasscodeCircularButton ()

@property (nonatomic, strong) CAShapeLayer *circle;
@property (nonatomic, strong) UIColor *lineColor;
@property (nonatomic, strong) UIColor *titleColor;
@property (nonatomic, strong) UIColor *fillColor;
@property (nonatomic, strong) UIColor *selectedLineColor;
@property (nonatomic, strong) UIColor *selectedFillColor;
@property (nonatomic, strong) UIColor *selectedTitleColor;
@property (nonatomic, strong) UIFont *font;

@end

@implementation PasscodeCircularButton

- (id)initWithNumber:(NSString *)number frame:(CGRect)frame style:(PasscodeButtonStyle *)style {
   
    self = [[PasscodeCircularButton alloc] initWithFrame:frame];
    
    if(self) {
        _lineColor = style.lineColor;
        _titleColor = style.titleColor;
        _fillColor = style.fillColor;
        _selectedLineColor = style.selectedLineColor;
        _selectedTitleColor = style.selectedTitleColor;
        _selectedFillColor = style.selectedFillColor;
        _font = style.titleFont;
        _circle = [CAShapeLayer layer];
        [_circle setBounds:CGRectMake(0.0f, 0.0f, [self bounds].size.width, [self bounds].size.height)];
        [_circle setPosition:CGPointMake(CGRectGetMidX([self bounds]),CGRectGetMidY([self bounds]))];
        UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame))];
        [_circle setPath:[path CGPath]];
        [_circle setStrokeColor:[self.lineColor CGColor]];
        [_circle setLineWidth:0.5f];
        [_circle setFillColor:self.fillColor.CGColor];
        [[self layer] addSublayer:self.circle];
        [self setTag:[number integerValue]];
        [self setTitle:number forState:UIControlStateNormal];
        [self setTitleColor:self.lineColor forState:UIControlStateNormal];
        self.titleLabel.font = self.font;
    }
    return self;
}

- (void)setHighlighted:(BOOL)highlighted {
    if (highlighted) {
        [self.circle setStrokeColor:self.selectedLineColor.CGColor];
        [self.circle setFillColor:self.selectedFillColor.CGColor];
        self.titleLabel.textColor = self.selectedTitleColor;
    }
    else {
        self.titleLabel.textColor = self.titleColor;
        [self.circle setFillColor:self.fillColor.CGColor];
        [self.circle setStrokeColor:self.lineColor.CGColor];
    }
}

@end