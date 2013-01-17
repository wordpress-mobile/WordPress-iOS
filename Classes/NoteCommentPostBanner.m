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
        [self setupShadow];
    }
    return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupShadow];
    }
    return self;
}

- (void)setupShadow{
    UIImage *shadowImage = [[UIImage imageNamed:@"note_header_shadow"] resizableImageWithCapInsets:UIEdgeInsetsMake(5.f, 0.f, 0.f, 0.f)];
    UIImageView *image = [[UIImageView alloc] initWithImage:shadowImage];
    image.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    CGRect imageFrame = self.frame;
    imageFrame.origin.y = CGRectGetMaxY(self.bounds);
    imageFrame.size.height = 6.f;
    image.frame = imageFrame;
    [self addSubview:image];
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
