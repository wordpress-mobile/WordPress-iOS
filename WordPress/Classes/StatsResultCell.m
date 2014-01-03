/*
 * StatsResultCell.m
 *
 * Copyright (c) 2014 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "StatsResultCell.h"

@implementation StatsResultCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setResultTitle:(NSString *)title {
    [self setLeftLabelText:title];
}

- (void)setResultCount:(NSNumber *)count {
    [self setRightLabelText:[count stringValue]];
}

@end
