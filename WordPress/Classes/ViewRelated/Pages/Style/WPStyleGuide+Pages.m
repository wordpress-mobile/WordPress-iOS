#import "WPStyleGuide+Pages.h"
#import <QuartzCore/QuartzCore.h>
#import "WordPress-Swift.h"

@import WordPressShared;
@import WordPressShared;

@implementation WPStyleGuide (Pages)

#pragma mark - Page Cell Styles

+ (void)applyRestorePageLabelStyle:(UILabel *)label
{
    label.font = [WPStyleGuide regularFont];
    label.textColor = [UIColor murielTextSubtle];
}

+ (void)applyRestorePageButtonStyle:(UIButton *)button
{
    [WPStyleGuide configureLabel:button.titleLabel
                       textStyle:UIFontTextStyleCallout
                      fontWeight:UIFontWeightSemibold];
    [button setTitleColor:[UIColor murielPrimary] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor murielPrimaryDark] forState:UIControlStateHighlighted];
    button.tintColor = [UIColor murielPrimary];
}

+ (UIFont *)regularFont {
    return [WPStyleGuide fontForTextStyle:UIFontTextStyleSubheadline maximumPointSize:[WPStyleGuide maxFontSize]];
}

@end
