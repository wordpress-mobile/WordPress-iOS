#import "ContentActionButton.h"
#import <QuartzCore/QuartzCore.h>
#import "WPStyleGuide.h"

CGFloat const BackingLayerCornerRadius = 8.0f;
CGFloat const BackingLayerVerticalPadding = 2.0f;
CGFloat const BackingLayerHorizontalPadding = 4.0f;

@interface ContentActionButton()

@property (nonatomic, strong) UIView *labelBubble;

@end

@implementation ContentActionButton

- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize newSize = [super sizeThatFits:size];
    if (self.labelBubble && CGRectGetWidth(self.labelBubble.frame) > 0) {
        CGFloat width = newSize.width;
        newSize.width = width + (BackingLayerHorizontalPadding * 2);
    }
    return newSize;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (self.labelBubble) {
        self.labelBubble.frame = [self frameForLabelBubble];
    }
}

- (void)setDrawLabelBubble:(BOOL)drawLabelBubble
{
    if (_drawLabelBubble == drawLabelBubble) {
        return;
    }

    _drawLabelBubble = drawLabelBubble;

    if (!_drawLabelBubble) {
        self.labelBubble = nil;
    } else {
        UIView *view = [[UIView alloc] initWithFrame:[self frameForLabelBubble]];
        view.layer.cornerRadius = BackingLayerCornerRadius;
        view.backgroundColor = [WPStyleGuide itsEverywhereGrey];
        self.labelBubble = view;
    }
}

- (void)setLabelBubble:(UIView *)labelBubble
{
    if (_labelBubble == labelBubble) {
        return;
    }

    if (_labelBubble) {
        [_labelBubble removeFromSuperview];
    }

    if (labelBubble) {
        self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _labelBubble = labelBubble;
        _labelBubble.userInteractionEnabled = NO;
        [self addSubview:_labelBubble];
        [self sendSubviewToBack:_labelBubble];
        [self setNeedsLayout];
    } else {
        self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        _labelBubble = nil;
    }
}

- (CGRect)frameForLabelBubble
{
    NSString *str = [self titleForState:UIControlStateNormal];
    CGRect frame = self.titleLabel.frame;

    CGFloat x = CGRectGetMinX(frame) - BackingLayerHorizontalPadding;
    CGFloat y = CGRectGetMinY(frame) - BackingLayerVerticalPadding;

    if ([str length] == 0) {
        return CGRectMake(x, y, 0.0f, 0.0f);
    }

    CGFloat w = CGRectGetWidth(frame) + BackingLayerHorizontalPadding * 2.0f;
    CGFloat h = CGRectGetHeight(frame) + BackingLayerVerticalPadding * 2.0f;

    return CGRectMake(x, y, w, h);
}

@end
