/*
 *  PasscodeCircularView.h
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import <UIKit/UIKit.h>

@interface PasscodeCircularView : UIView

- (id)initWithFrame:(CGRect)frame lineColor:(UIColor *) lineColor fillColor:(UIColor *) fillColor;
- (void)fill;
- (void)clear;

@end
