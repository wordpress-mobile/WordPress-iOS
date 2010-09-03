//
//  TransparentToolbar.m
//  WordPress
//
//  Created by Chris Boyd on 9/3/10.
//

#import "TransparentToolbar.h"

@implementation TransparentToolbar

- (void)drawRect:(CGRect)rect {
}

- (void) applyTranslucentBackground {
    self.backgroundColor = [UIColor clearColor];
    self.opaque = NO;
    self.translucent = YES;
}

- (id) init {
    self = [super init];
    [self applyTranslucentBackground];
    return self;
}

- (id) initWithFrame:(CGRect) frame {
    self = [super initWithFrame:frame];
    [self applyTranslucentBackground];
    return self;
}

@end
