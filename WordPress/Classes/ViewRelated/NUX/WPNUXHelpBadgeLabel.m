#import "WPNUXHelpBadgeLabel.h"
#import <WordPressShared/UIColor+Helpers.h>
#import <WordPressShared/WPFontManager.h>

@implementation WPNUXHelpBadgeLabel

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonSetup];
    }
    return self;
}

- (void)commonSetup
{
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = 6.0;
    self.textAlignment = NSTextAlignmentCenter;
    self.backgroundColor = [UIColor UIColorFromHex:0xdd3d36];
    self.textColor = [UIColor whiteColor];
    self.font = [WPFontManager systemRegularFontOfSize:8.0];
}

- (void)drawTextInRect:(CGRect)rect
{
    UIEdgeInsets insets = {0, 0, 1, 0};
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, insets)];
}

@end
