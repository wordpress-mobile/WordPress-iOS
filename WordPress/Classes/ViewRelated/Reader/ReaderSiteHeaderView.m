#import "ReaderSiteHeaderView.h"

@implementation ReaderSiteHeaderView

- (UILabel *)newLabelForTitle
{
    UILabel *label = [super newLabelForTitle];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [WPStyleGuide littleEddieGrey];
    return label;
}

- (UILabel *)newLabelForSubtitle
{
    UILabel *label = [super newLabelForSubtitle];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [WPStyleGuide allTAllShadeGrey];
    return label;
}

@end
