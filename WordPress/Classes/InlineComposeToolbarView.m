#import "InlineComposeToolbarView.h"

CGFloat InlineComposeToolbarViewMaxToolbarWidth = 600.f;
CGFloat InlineComposeToolbarViewMinToolbarWidth = 320.f;

@interface InlineComposeToolbarView ()

@property (nonatomic) CGFloat maxToolbarWidth;
@property (nonatomic) CGFloat minToolbarWidth;
@property (nonatomic) CALayer *borderLayer;

@end

@implementation InlineComposeToolbarView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setDefaulsPropertyValues];
   }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setDefaulsPropertyValues];
    }
    return self;
}

- (void)setDefaulsPropertyValues {
    _maxToolbarWidth = InlineComposeToolbarViewMaxToolbarWidth;
    _minToolbarWidth = InlineComposeToolbarViewMinToolbarWidth;
    _borderColor = [UIColor colorWithWhite:0.88f alpha:1.f];
    [self addBorder];
}

- (void)dealloc {
    self.borderColor = nil;
    self.borderLayer = nil;
}

- (void)addBorder {
    _borderLayer = [CALayer layer];
    _borderLayer.backgroundColor = [self.borderColor CGColor];

    CGRect borderFrame = self.frame;
    borderFrame.size.height = 1.f;

    _borderLayer.frame = borderFrame;

    [self.layer addSublayer:_borderLayer];

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

    if (!self.composerContainerView){
        return;
    }

    // constrain frame width and center it
    CGRect frame = self.composerContainerView.frame;
    frame.size.width = MIN(self.maxToolbarWidth, self.bounds.size.width);
    frame.origin.x = (CGRectGetWidth(self.bounds) - CGRectGetWidth(frame)) * 0.5f;

    self.composerContainerView.frame = frame;

    frame.size.height = 1.f;
    self.borderLayer.frame = frame;

}

@end
