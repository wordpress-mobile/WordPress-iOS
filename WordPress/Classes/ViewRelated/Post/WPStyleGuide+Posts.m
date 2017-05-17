#import "WPStyleGuide+Posts.h"
#import <WordPressShared/WPFontManager.h>
#import "WordPress-Swift.h"
#import <QuartzCore/QuartzCore.h>

@implementation WPStyleGuide (Posts)

#pragma mark - Post List Styles

+ (void)applyPostAuthorFilterStyle:(UISegmentedControl *)segmentControl
{
    NSDictionary *attributes = @{NSFontAttributeName: [self deviceDependantFontForLabels]};
    [segmentControl setTitleTextAttributes:attributes forState:UIControlStateNormal];
    segmentControl.tintColor = [WPStyleGuide grey];
    segmentControl.backgroundColor = [UIColor whiteColor];
    segmentControl.clipsToBounds = YES;
    segmentControl.layer.cornerRadius = 3.0; // Clip the corners of the background color.
}

+ (UIColor *)postListSearchBarTextColor
{
    return [UIDevice isPad] ? [UIColor colorWithRed:142.0/255.0 green:142.0/255.0 blue:147.0/255.0 alpha:1.0] : [UIColor whiteColor];
}


#pragma mark - Card View Styles

+ (UIColor *)postCardBorderColor
{
    return [UIColor colorWithRed:215.0/255.0 green:227.0/255.0 blue:235.0/255.0 alpha:1.0];
}

+ (void)applyPostCardStyle:(UITableViewCell *)cell
{
    cell.backgroundColor = [self greyLighten30];
    cell.contentView.backgroundColor = [self greyLighten30];
}

+ (void)applyPostAuthorSiteStyle:(UILabel *)label
{
    [self configureLabelForRegularFontStyle:label];
    label.textColor = [self greyDarken20];
}

+ (void)applyPostAuthorNameStyle:(UILabel *)label
{
    [self configureLabelForSmallFontStyle:label];
    label.textColor = [self grey];
}

+ (void)applyPostTitleStyle:(UILabel *)label
{
    label.textColor = [self darkGrey];
}

+ (void)applyPostSnippetStyle:(UILabel *)label
{
    label.textColor = [self darkGrey];
}

+ (void)applyPostDateStyle:(UILabel *)label
{
    [self configureLabelForDeviceDependantStyle:label];
    label.textColor = [self grey];
}

+ (void)applyPostStatusStyle:(UILabel *)label
{
    [self configureLabelForDeviceDependantStyle:label];
    label.textColor = [self grey];
}

+ (void)applyPostMetaButtonStyle:(UIButton *)button
{
    [self configureLabelForDeviceDependantStyle:button.titleLabel];
    [button setTitleColor:[self grey] forState:UIControlStateNormal];
}

+ (void)applyRestorePostLabelStyle:(UILabel *)label
{
    [self configureLabelForDeviceDependantStyle:label];
    label.textColor = [self grey];
}

+ (void)applyRestorePostButtonStyle:(UIButton *)button
{
    [self configureLabelForSmallFontStyle:button.titleLabel];
    [button setTitleColor:[WPStyleGuide wordPressBlue] forState:UIControlStateNormal];
    [button setTitleColor:[WPStyleGuide darkBlue] forState:UIControlStateHighlighted];
}

#pragma mark - Attributed String Attributes

+ (NSDictionary *)postCardAuthorSiteAttributes
{
    UIFont *font = [self regularFont];
    CGFloat lineHeight = font.pointSize * 1.5;
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = lineHeight;
    paragraphStyle.maximumLineHeight = lineHeight;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : font};
}

+ (NSDictionary *)postCardAuthorNameAttributes
{
    UIFont *font = [self smallFont];
    CGFloat lineHeight = font.pointSize * 1.5;
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = lineHeight;
    paragraphStyle.maximumLineHeight = lineHeight;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : font};
}

+ (NSDictionary *)postCardTitleAttributes
{
    UIFont *font = [WPStyleGuide notoBoldFontForTextStyle:UIFontTextStyleHeadline];
    CGFloat lineHeight = font.pointSize * 1.5;
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = lineHeight;
    paragraphStyle.maximumLineHeight = lineHeight;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : font};
}

+ (NSDictionary *)postCardSnippetAttributes
{
    UIFontTextStyle textStyle = [UIDevice isPad] ? UIFontTextStyleCallout : UIFontTextStyleSubheadline;
    UIFont *font = [WPStyleGuide notoFontForTextStyle:textStyle];
    CGFloat lineHeight = font.pointSize * 1.5;
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = lineHeight;
    paragraphStyle.maximumLineHeight = lineHeight;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : font};
}

+ (NSDictionary *)postCardDateAttributes
{
    UIFont *font = [self deviceDependantFontForLabels];
    CGFloat lineHeight = font.pointSize * 1.5;
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = lineHeight;
    paragraphStyle.maximumLineHeight = lineHeight;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : font};
}

+ (NSDictionary *)postCardStatusAttributes
{
    UIFont *font = [self deviceDependantFontForLabels];
    CGFloat lineHeight = font.pointSize * 1.5;
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = lineHeight;
    paragraphStyle.maximumLineHeight = lineHeight;
    return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : font};
}

+ (CGRect)navigationBarButtonRect
{
    return CGRectMake(0.0f, 0.0f, 30.0f, 30.0f);
};

+ (CGFloat)spacingBetweeenNavbarButtons
{
    return 40.0f;
}

+ (WPButtonForNavigationBar*)buttonForBarWithImage:(UIImage *)image
                                            target:(id)target
                                          selector:(SEL)selector
{
    WPButtonForNavigationBar* button = [[WPButtonForNavigationBar alloc] initWithFrame:[self navigationBarButtonRect]];
    
    button.tintColor = [UIColor whiteColor];
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
    button.removeDefaultLeftSpacing = YES;
    button.removeDefaultRightSpacing = YES;
    button.rightSpacing = [self spacingBetweeenNavbarButtons] / 2.0f;
    button.leftSpacing = [self spacingBetweeenNavbarButtons] / 2.0f;
    
    return button;
}


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
    paragraphStyle.lineSpacing = 4.0;
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
    [self configureLabelForRegularFontStyle:label];
    label.textColor = [self grey];
}

+ (void)applyRestorePageButtonStyle:(UIButton *)button
{
    [WPStyleGuide configureLabel:button.titleLabel
                    forTextStyle:UIFontTextStyleCallout
                      withWeight:UIFontWeightSemibold];
    [button setTitleColor:[WPStyleGuide wordPressBlue] forState:UIControlStateNormal];
    [button setTitleColor:[WPStyleGuide darkBlue] forState:UIControlStateHighlighted];
}

+ (UIFont *)deviceDependantFontForLabels {
    UIFontTextStyle textStyle = [UIDevice isPad] ? UIFontTextStyleSubheadline : UIFontTextStyleCaption1;
    return [WPStyleGuide fontForTextStyle:textStyle];
}

+ (UIFont *)regularFont {
    return [WPStyleGuide fontForTextStyle:UIFontTextStyleSubheadline];
}

+ (UIFont *)smallFont {
    return [WPStyleGuide fontForTextStyle:UIFontTextStyleCaption1];
}

+ (void)configureLabelForDeviceDependantStyle:(UILabel *)label {
    UIFontTextStyle textStyle = [UIDevice isPad] ? UIFontTextStyleSubheadline : UIFontTextStyleCaption1;
    [WPStyleGuide configureLabel:label forTextStyle:textStyle];
}

+ (void)configureLabelForRegularFontStyle:(UILabel *)label {
    [WPStyleGuide configureLabel:label forTextStyle:UIFontTextStyleSubheadline];
}

+ (void)configureLabelForSmallFontStyle:(UILabel *)label {
    [WPStyleGuide configureLabel:label forTextStyle:UIFontTextStyleCaption1];
}

@end
