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
    if (self.textLabelBackingLayer && CGRectGetWidth(self.textLabelBackingLayer.frame) > 0) {
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

    [self layoutBackingLabel];
}

- (void)layoutBackingLabel
{
    NSString *str = [self titleForState:UIControlStateNormal];
    if ([str length] == 0) {
        self.textLabelBackingLayer.frame = CGRectZero;
        return;
    }

    CGRect frame = self.titleLabel.frame;
    CGFloat x = CGRectGetMinX(frame) - BackingLayerHorizontalPadding;
    CGFloat y = CGRectGetMinY(frame) - BackingLayerVerticalPadding;
    CGFloat w = CGRectGetWidth(frame) + BackingLayerHorizontalPadding * 2.0f;
    CGFloat h = CGRectGetHeight(frame) + BackingLayerVerticalPadding * 2.0f;
    self.textLabelBackingLayer.frame = CGRectMake(x, y, w, h);
}

- (void)setDrawsTitleBubble:(BOOL)drawsTitleBubble
{
    if (_drawsTitleBubble == drawsTitleBubble) {
        return;
    }

    _drawsTitleBubble = drawsTitleBubble;

    if (!_drawsTitleBubble) {
        self.textLabelBackingLayer = nil;
    } else {
        CALayer *layer = [[CALayer alloc] init];
        layer.zPosition = -1;
        layer.cornerRadius = BackingLayerCornerRadius;
        layer.backgroundColor = [[WPStyleGuide itsEverywhereGrey] CGColor];
        self.textLabelBackingLayer = layer;
    }
}

- (void)setTextLabelBackingLayer:(CALayer *)textLabelBackingLayer
{
    if (_textLabelBackingLayer == textLabelBackingLayer) {
        return;
    }

    if (_textLabelBackingLayer) {
        [_textLabelBackingLayer removeFromSuperlayer];
    }

    if (textLabelBackingLayer) {
        self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _textLabelBackingLayer = textLabelBackingLayer;
        [self.layer addSublayer:_textLabelBackingLayer];
        [self setNeedsLayout];
    } else {
        self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        _textLabelBackingLayer = nil;
    }
}

@end
