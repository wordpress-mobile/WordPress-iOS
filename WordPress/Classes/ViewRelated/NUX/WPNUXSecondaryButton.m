#import "WPNUXSecondaryButton.h"
#import <WordPress-iOS-Shared/WPFontManager.h>

@implementation WPNUXSecondaryButton

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
    frame.size.width += self.titleEdgeInsets.left + self.titleEdgeInsets.right;
    self.frame = frame;
}

- (CGSize)intrinsicContentSize
{
    CGSize size = [self sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    size.width += self.titleEdgeInsets.left + self.titleEdgeInsets.right;
    return size;
}

#pragma mark - Private Methods

- (void)configureButton
{
    self.titleLabel.font = [WPFontManager openSansRegularFontOfSize:15.0];
    self.titleLabel.minimumScaleFactor = 10.0/15.0;
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    [self setTitleEdgeInsets:UIEdgeInsetsMake(0, 15.0, 0, 15.0)];
    [self setTitleColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    [self setTitleColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.4] forState:UIControlStateHighlighted];
}

@end
