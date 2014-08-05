#import "WPNUXBackButton.h"
#import <WordPress-iOS-Shared/WPFontManager.h>

@implementation WPNUXBackButton

// There's some extra space in the btn-back and btn-back-tap images to improve the
// tap area of this image and in order for sizeToFit to work correctly we have to take
// this extra space into account.
CGFloat const WPNUXBackButtonExtraHorizontalWidthForSpace = 30;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self configureButton];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
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
    self.titleLabel.font = [WPFontManager openSansRegularFontOfSize:16.0];
    [self setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 6.0, 0, 10.0)];
    [self setTitleColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.8] forState:UIControlStateNormal];
    [self setTitleColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5] forState:UIControlStateHighlighted];
    [self setImageEdgeInsets:UIEdgeInsetsMake(0, -18, 0, 0)];
    [self setImage:[UIImage imageNamed:@"btn-back-chevron"] forState:UIControlStateNormal];
    [self setImage:[UIImage imageNamed:@"btn-back-chevron-tapped"] forState:UIControlStateHighlighted];
    [self setTitle:NSLocalizedString(@"Back", nil) forState:UIControlStateNormal];
}

@end
