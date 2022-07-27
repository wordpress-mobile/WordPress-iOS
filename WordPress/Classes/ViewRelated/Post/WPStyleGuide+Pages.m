#import "WPStyleGuide+Pages.h"
#import <WordPressShared/WPFontManager.h>
#import <QuartzCore/QuartzCore.h>
#import <WordPressUI/WordPressUI.h>
#import "WordPress-Swift.h"

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

+ (void)applyRestoreSavedPostLabelStyle:(UILabel *)label
{
    [WPStyleGuide configureLabel:label textStyle:UIFontTextStyleCallout];
    label.textColor = [UIColor murielTextSubtle];
}

+ (void)applyRestoreSavedPostTitleLabelStyle:(UILabel *)label
{
    [WPStyleGuide configureLabel:label
                       textStyle:UIFontTextStyleCallout
                      fontWeight:UIFontWeightSemibold];

    UIFontDescriptor *descriptor = [label.font fontDescriptor];
    UIFontDescriptorSymbolicTraits traits = [descriptor symbolicTraits];
    descriptor = [descriptor fontDescriptorWithSymbolicTraits:traits | UIFontDescriptorTraitItalic];
    label.font = [UIFont fontWithDescriptor:descriptor size:label.font.pointSize];
    label.textColor = [UIColor murielTextSubtle];
}

+ (void)applyRestoreSavedPostButtonStyle:(UIButton *)button
{
    [WPStyleGuide configureLabel:button.titleLabel
                       textStyle:UIFontTextStyleCallout
                      fontWeight:UIFontWeightSemibold];
    [button setTitleColor:[UIColor murielPrimary] forState:UIControlStateNormal];
}

+ (UIFont *)regularFont {
    return [WPStyleGuide fontForTextStyle:UIFontTextStyleSubheadline maximumPointSize:[WPStyleGuide maxFontSize]];
}

+ (UIFont *)smallFont {
    return [WPStyleGuide fontForTextStyle:UIFontTextStyleCaption1 maximumPointSize:[WPStyleGuide maxFontSize]];
}

@end
