#import "WPNUXHelpBadgeLabel.h"

@implementation WPNUXHelpBadgeLabel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)drawTextInRect:(CGRect)rect {
    UIEdgeInsets insets = {0, 0, 1, 0};
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, insets)];
}

@end
