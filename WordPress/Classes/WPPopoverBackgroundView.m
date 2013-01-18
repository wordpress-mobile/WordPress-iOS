//
//  WPPopoverBackgroundView.m
//  WordPress
//
//  Created by Eric Johnson on 7/16/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "WPPopoverBackgroundView.h"

@implementation WPPopoverBackgroundView

@synthesize arrowDirection = _arrowDirection;
@synthesize arrowOffset = _arrowOffset;
@synthesize borderImageView;
@synthesize arrowImageView;

#define CONTENT_INSET 8.0f
#define CAP_INSET 30.0f
#define ARROW_BASE 30.0f
#define ARROW_HEIGHT 16.0f

#pragma mark -
#pragma mark Class Methods

+ (UIEdgeInsets)contentViewInsets {
    return UIEdgeInsetsMake(CONTENT_INSET, CONTENT_INSET, CONTENT_INSET, CONTENT_INSET);
}

+ (CGFloat)arrowBase {
    return ARROW_BASE;
}

+ (CGFloat)arrowHeight {
    return ARROW_HEIGHT;
}


#pragma mark -
#pragma mark Instance Methods

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UIImage *img = [[UIImage imageNamed:@"popover_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(CAP_INSET,CAP_INSET,CAP_INSET,CAP_INSET)];
        self.borderImageView = [[UIImageView alloc] initWithImage:img];
        self.arrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"popover_arrow"]];
        
        [self addSubview:borderImageView];
        [self insertSubview:arrowImageView aboveSubview:borderImageView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat height = self.frame.size.height;
    CGFloat width = self.frame.size.width;
    CGFloat left = 0.0;
    CGFloat top = 0.0;
    CGFloat coordinate = 0.0;
    CGAffineTransform rotation = CGAffineTransformIdentity;

    switch (self.arrowDirection) {
        case UIPopoverArrowDirectionUp:
            top += ARROW_HEIGHT;
            height -= ARROW_HEIGHT;
            coordinate = ((width / 2) + self.arrowOffset) - (ARROW_BASE/2);
            coordinate = MIN(MAX(CAP_INSET, coordinate), width - (CAP_INSET + (ARROW_BASE / 2)));
            self.arrowImageView.frame = CGRectMake(coordinate, 1.0f, ARROW_BASE, ARROW_HEIGHT);            
            break;

        case UIPopoverArrowDirectionDown:
            height -= ARROW_HEIGHT;
            coordinate = ((width / 2) + self.arrowOffset) - (ARROW_BASE/2);
            coordinate = MIN(MAX(CAP_INSET, coordinate), width - (CAP_INSET + (ARROW_BASE / 2)));
            arrowImageView.frame = CGRectMake(coordinate, height-1.0f, ARROW_BASE, ARROW_HEIGHT); 
            rotation = CGAffineTransformMakeRotation( M_PI );
            break;
            
        case UIPopoverArrowDirectionLeft:
            left += ARROW_BASE;
            width -= ARROW_BASE;
            coordinate = ((height / 2) + self.arrowOffset) - (ARROW_HEIGHT/2);
            coordinate = MIN(MAX(CAP_INSET, coordinate), height - (CAP_INSET + (ARROW_BASE / 2)));
            arrowImageView.frame = CGRectMake(1.0f, coordinate, ARROW_BASE, ARROW_HEIGHT); 
            rotation = CGAffineTransformMakeRotation( -M_PI_2 );
            break;
            
        case UIPopoverArrowDirectionRight:
            width -= ARROW_BASE;
            coordinate = ((height / 2) + self.arrowOffset)- (ARROW_HEIGHT/2);
            coordinate = MIN(MAX(CAP_INSET, coordinate), height - (CAP_INSET + (ARROW_BASE / 2)));
            arrowImageView.frame = CGRectMake(width-1.0f, coordinate, ARROW_BASE, ARROW_HEIGHT); 
            rotation = CGAffineTransformMakeRotation( M_PI_2 );
            break;
        default:
            break;
    }
    
    self.borderImageView.frame = CGRectMake(left, top, width, height);
    
    [arrowImageView setTransform:rotation];
}

- (void)setArrowOffset:(CGFloat)offset {
    _arrowOffset = offset;
    [self setNeedsLayout];
}

- (void)setArrowDirection:(UIPopoverArrowDirection)direction {
    _arrowDirection = direction;
    [self setNeedsLayout];
}

@end
