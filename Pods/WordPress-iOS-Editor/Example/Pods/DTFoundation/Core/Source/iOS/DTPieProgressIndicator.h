//
//  DTPieProgressIndicator.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 16.05.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

/**
 A Progress indicator shaped like a pie chart.
 */

@interface DTPieProgressIndicator : UIView

/**
 The progress in percent
 */
@property (nonatomic, assign) CGFloat progressPercent;

/**
 The color of the pie
 */
@property (nonatomic, strong) UIColor *color;

/**
 Creates a pie progress indicator of the correct size
 */
+ (DTPieProgressIndicator *)pieProgressIndicator;

@end
