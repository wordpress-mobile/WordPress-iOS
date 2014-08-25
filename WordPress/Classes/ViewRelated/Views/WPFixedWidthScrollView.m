#import "WPFixedWidthScrollView.h"

@implementation WPFixedWidthScrollView

- (instancetype)initWithRootView:(UIView *)view
{
    self = [self initWithFrame:CGRectZero];
    if (self) {
        self.rootView = view;
        [self addSubview:self.rootView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    CGFloat width = viewWidth > self.contentWidth && self.contentWidth > 0 ? self.contentWidth : viewWidth;
    CGFloat height = [self.rootView sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)].height;
    self.rootView.frame = CGRectMake((viewWidth - width) / 2, 0, width, height);
    self.contentSize = CGSizeMake(viewWidth, height);
}

@end
