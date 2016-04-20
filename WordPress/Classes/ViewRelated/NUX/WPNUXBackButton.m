#import "WPNUXBackButton.h"
#import <WordPressShared/WPFontManager.h>

@implementation WPNUXBackButton

// There's some extra space in the btn-back and btn-back-tap images to improve the
// tap area of this image and in order for sizeToFit to work correctly we have to take
// this extra space into account.
static CGFloat const WPNUXBackButtonExtraHorizontalWidthForSpace    = 30;
static UIEdgeInsets const WPNUXBackButtonTitleEdgeInsets            = {0.0, 0.0, 0, 10.0};
static UIEdgeInsets const WPNUXBackButtonImageEdgeInsets            = {0, -22, 0, 0};

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self configureButton];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self configureButton];
    }
    return self;
}

- (void)sizeToFit
{
    [super sizeToFit];

    // Adjust frame to account for the edge insets
    CGRect frame = self.frame;
    frame.size.width += self.titleEdgeInsets.left + self.titleEdgeInsets.right + WPNUXBackButtonExtraHorizontalWidthForSpace;
    self.frame = frame;
}

- (CGSize)intrinsicContentSize
{
    CGSize size = [self sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    size.width += self.titleEdgeInsets.left + self.titleEdgeInsets.right + WPNUXBackButtonExtraHorizontalWidthForSpace;
    return size;
}

- (void)configureButton
{
    self.titleLabel.font = [WPFontManager systemRegularFontOfSize:15.0];
    [self setTitleEdgeInsets:WPNUXBackButtonTitleEdgeInsets];
    [self setTitleColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    [self setTitleColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.4] forState:UIControlStateHighlighted];
    [self setImageEdgeInsets:WPNUXBackButtonImageEdgeInsets];
    [self setImage:[UIImage imageNamed:@"btn-back-chevron"] forState:UIControlStateNormal];
    [self setImage:[UIImage imageNamed:@"btn-back-chevron-tapped"] forState:UIControlStateHighlighted];
    [self setTitle:NSLocalizedString(@"Back", nil) forState:UIControlStateNormal];
}

@end
