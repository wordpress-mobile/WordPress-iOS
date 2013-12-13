//
//  InlineComposeToolbarView.m
//  WordPress
//
//  Created by Beau Collins on 12/12/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "InlineComposeToolbarView.h"

CGFloat InlineComposeToolbarViewMaxToolbarWidth = 600.f;
CGFloat InlineComposeToolbarViewMinToolbarWidth = 320.f;

@interface InlineComposeToolbarView ()

@property (nonatomic) CGFloat maxToolbarWidth;
@property (nonatomic) CGFloat minToolbarWidth;

@end

@implementation InlineComposeToolbarView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _maxToolbarWidth = InlineComposeToolbarViewMaxToolbarWidth;
        _minToolbarWidth = InlineComposeToolbarViewMinToolbarWidth;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _maxToolbarWidth = InlineComposeToolbarViewMaxToolbarWidth;
        _minToolbarWidth = InlineComposeToolbarViewMinToolbarWidth;
    }
    return self;
}

- (void)setMaxToolbarWidth:(CGFloat)maxToolbarWidth {
    if (maxToolbarWidth == _maxToolbarWidth) {
        return;
    }

    _maxToolbarWidth = maxToolbarWidth;

    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    if (!self.composerContainerView) return;

    // constrain frame width and center it
    CGRect frame = self.composerContainerView.frame;
    frame.size.width = MIN(self.maxToolbarWidth, self.bounds.size.width);
    frame.origin.x = (CGRectGetWidth(self.bounds) - CGRectGetWidth(frame)) * 0.5f;

    self.composerContainerView.frame = frame;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
