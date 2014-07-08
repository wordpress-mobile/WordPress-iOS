//
//  SPAuthenticationView.m
//  Simplenote-OSX
//
//  Created by Michael Johnston on 7/20/13.
//  Copyright (c) 2013 Simperium. All rights reserved.
//

#import "SPAuthenticationView.h"

@implementation SPAuthenticationView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)drawRect:(NSRect)rect {    
    [[NSColor clearColor] set];
    NSRectFill([self frame]);
    
    [[NSColor colorWithCalibratedWhite:1.0 alpha:1.0] set];
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:[self frame] xRadius:12.0 yRadius:12.0];
    [path addClip];
    NSRectFill([self frame]);
}

@end
