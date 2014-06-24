//
//  CustomHighlightButton.m
//  WordPress
//
//  Created by Christopher Truman on 6/24/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "CustomHighlightButton.h"

@implementation CustomHighlightButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)setHighlighted:(BOOL)highlighted{
    [UIView animateWithDuration:0.2 animations:^(){
        self.imageView.alpha = highlighted ? 0.3 : 1.0;
    }];
}

@end
