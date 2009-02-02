//
//  WPLabelFooterView.m
//  WordPress
//
//  Created by JanakiRam on 02/02/09.
//  Copyright 2008 Prithvi Information Solutions Limited. All rights reserved.
//

#import "WPLabelFooterView.h"


@implementation WPLabelFooterView

@synthesize label;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
		self.backgroundColor = [UIColor clearColor];
		label = [[UILabel alloc] initWithFrame:frame];
		label.backgroundColor = [UIColor clearColor];
		label.font = [UIFont systemFontOfSize:15.5];
		label.textColor = [[UIColor colorWithRed:0.2 green:0.25 blue:0.35 alpha:1.0] colorWithAlphaComponent:0.8];
		label.shadowColor = [[UIColor whiteColor] colorWithAlphaComponent:0.9];
		label.shadowOffset = CGSizeMake(0.3, 0.4);
		self.label = label;
		[self addSubview:label];
		self.autoresizesSubviews = YES;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth ;
		label.autoresizingMask = UIViewAutoresizingFlexibleWidth ;
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
    // Drawing code
}

- (void)dealloc 
{
    [label release];
    [super dealloc];
}


@end
