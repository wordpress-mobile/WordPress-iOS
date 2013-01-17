//
//  NoteCommentPostBanner.m
//  WordPress
//
//  Created by Beau Collins on 12/6/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "NoteCommentPostBanner.h"

@implementation NoteCommentPostBanner

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        NSLog(@"Decoded banner");
    }
    return self;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
 
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    self.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1.f];
    return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    self.backgroundColor = [UIColor whiteColor];
}


@end
