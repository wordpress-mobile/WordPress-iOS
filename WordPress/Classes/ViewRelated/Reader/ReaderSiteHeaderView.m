#import "ReaderSiteHeaderView.h"

@implementation ReaderSiteHeaderView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [WPStyleGuide baseDarkerBlue];
    }
    return self;
}

- (UILabel *)newLabelForTitle
{
    UILabel *label = [super newLabelForTitle];
    label.backgroundColor = [WPStyleGuide baseDarkerBlue];
    label.textColor = [WPStyleGuide littleEddieGrey];
    return label;
}

- (UILabel *)newLabelForSubtitle
{
    UILabel *label = [super newLabelForSubtitle];
    label.backgroundColor = [WPStyleGuide baseDarkerBlue];
    label.textColor = [WPStyleGuide allTAllShadeGrey];
    return label;
}

@end
