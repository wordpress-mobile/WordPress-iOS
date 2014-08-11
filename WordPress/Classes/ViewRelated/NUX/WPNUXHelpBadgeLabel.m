#import "WPNUXHelpBadgeLabel.h"

@implementation WPNUXHelpBadgeLabel

- (void)drawTextInRect:(CGRect)rect
{
    UIEdgeInsets insets = {0, 0, 1, 0};
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, insets)];
}

@end
