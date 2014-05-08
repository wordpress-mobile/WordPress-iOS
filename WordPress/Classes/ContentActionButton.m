#import "ContentActionButton.h"
#import <QuartzCore/QuartzCore.h>
#import "WPStyleGuide.h"

CGFloat const BackingLayerCornerRadius = 8.0f;
CGFloat const BackingLayerVerticalPadding = 2.0f;
CGFloat const BackingLayerHorizontalPadding = 4.0f;

@interface ContentActionButton()

@property (nonatomic, strong) CALayer *textLabelBackingLayer;

@end

@implementation ContentActionButton

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    self.alpha = highlighted ? .5f : 1.f;
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize newSize = [super sizeThatFits:size];
    if (self.textLabelBackingLayer) {
        CGFloat width = newSize.width;
        newSize.width = width + (BackingLayerHorizontalPadding * 2);
    }
    return newSize;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (!self.drawsTitleBubble) {
        return;
    }

    if ([self.titleLabel.text length] > 0) {
        [self layoutBackingLabel];
    } else {
        [self.textLabelBackingLayer removeFromSuperlayer];
        self.textLabelBackingLayer = nil;
    }
}

- (void)layoutBackingLabel
{
    if(!self.textLabelBackingLayer) {
        CALayer *layer = [[CALayer alloc] init];
        layer.zPosition = -1;
        layer.cornerRadius = BackingLayerCornerRadius;
        layer.backgroundColor = [[WPStyleGuide itsEverywhereGrey] CGColor];
        self.textLabelBackingLayer = layer;
        [self.layer addSublayer:self.textLabelBackingLayer];
    }

    CGRect frame = self.titleLabel.frame;
    CGFloat x = CGRectGetMinX(frame) - BackingLayerHorizontalPadding;
    CGFloat y = CGRectGetMinY(frame) - BackingLayerVerticalPadding;
    CGFloat w = CGRectGetWidth(frame) + BackingLayerHorizontalPadding * 2.0f;
    CGFloat h = CGRectGetHeight(frame) + BackingLayerVerticalPadding * 2.0f;
    self.textLabelBackingLayer.frame = CGRectMake(x, y, w, h);
}

@end
