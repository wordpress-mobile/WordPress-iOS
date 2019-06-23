#import "WPStyleGuide+Posts.h"
#import <WordPressShared/WPFontManager.h>
#import <QuartzCore/QuartzCore.h>
#import <WordPressUI/WordPressUI.h>
#import "WordPress-Swift.h"

@implementation WPStyleGuide (Posts)

#pragma mark - Page Cell Styles

+ (void)applyPageTitleStyle:(UILabel *)label
{
    CGFloat fontSize = 15.0;
    label.font = [WPFontManager notoRegularFontOfSize:fontSize];
    label.textColor = [self wordPressBlue];
}

+ (NSDictionary *)pageCellTitleAttributes
{
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : [WPStyleGuide notoFontForTextStyle:UIFontTextStyleSubheadline]};
}

+ (void)applySectionHeaderTitleStyle:(UILabel *)label
{
    [self configureLabelForSmallFontStyle:label];
    label.backgroundColor = [self lightGrey];
    label.textColor = [self grey];
}

+ (void)applyRestorePageLabelStyle:(UILabel *)label
{
    label.font = [WPStyleGuide regularFont];
    label.textColor = [self grey];
}

+ (void)applyRestorePageButtonStyle:(UIButton *)button
{
    [WPStyleGuide configureLabel:button.titleLabel
                       textStyle:UIFontTextStyleCallout
                      fontWeight:UIFontWeightSemibold];
    [button setTitleColor:[WPStyleGuide wordPressBlue] forState:UIControlStateNormal];
    [button setTitleColor:[WPStyleGuide darkBlue] forState:UIControlStateHighlighted];
}

+ (void)applyRestoreSavedPostLabelStyle:(UILabel *)label
{
    [WPStyleGuide configureLabel:label textStyle:UIFontTextStyleCallout];
    label.textColor = [self greyDarken10];
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
    label.textColor = [self greyDarken10];
}

+ (void)applyRestoreSavedPostButtonStyle:(UIButton *)button
{
    [WPStyleGuide configureLabel:button.titleLabel
                       textStyle:UIFontTextStyleCallout
                      fontWeight:UIFontWeightSemibold];
    [button setTitleColor:[WPStyleGuide wordPressBlue] forState:UIControlStateNormal];
    [button setTitleColor:[WPStyleGuide darkBlue] forState:UIControlStateHighlighted];
}

+ (UIFont *)deviceDependantFontForLabels {
    UIFontTextStyle textStyle = [UIDevice isPad] ? UIFontTextStyleSubheadline : UIFontTextStyleCaption1;
    return [WPStyleGuide fontForTextStyle:textStyle maximumPointSize:[WPStyleGuide maxFontSize]];
}

+ (UIFont *)regularFont {
    return [WPStyleGuide fontForTextStyle:UIFontTextStyleSubheadline maximumPointSize:[WPStyleGuide maxFontSize]];
}

+ (UIFont *)smallFont {
    return [WPStyleGuide fontForTextStyle:UIFontTextStyleCaption1 maximumPointSize:[WPStyleGuide maxFontSize]];
}

+ (void)configureLabelForDeviceDependantStyle:(UILabel *)label {
    UIFontTextStyle textStyle = [UIDevice isPad] ? UIFontTextStyleSubheadline : UIFontTextStyleCaption1;
    [WPStyleGuide configureLabel:label textStyle:textStyle];
}

+ (void)configureLabelForRegularFontStyle:(UILabel *)label {
    [WPStyleGuide configureLabel:label textStyle:UIFontTextStyleSubheadline];
}

+ (void)configureLabelForSmallFontStyle:(UILabel *)label {
    [WPStyleGuide configureLabel:label textStyle:UIFontTextStyleCaption1];
}

@end
