#import "WPNUXUtility.h"
#import "WPFontManager.h"

@implementation WPNUXUtility

#pragma mark - Fonts

+ (UIFont *)textFieldFont
{
    return [WPFontManager systemRegularFontOfSize:16.0];
}

+ (UIFont *)descriptionTextFont
{
    return [WPFontManager systemRegularFontOfSize:15.0];
}

+ (UIFont *)titleFont
{
    return [WPFontManager systemLightFontOfSize:24.0];
}

+ (UIFont *)swipeToContinueFont
{
    return [WPFontManager systemRegularFontOfSize:10.0];
}

+ (UIFont *)tosLabelFont
{
    return [WPFontManager systemRegularFontOfSize:12.0];
}

+ (UIFont *)tosLabelSmallerFont
{
    return [WPFontManager systemRegularFontOfSize:9.0];
}

+ (UIFont *)confirmationLabelFont
{
    return [WPFontManager systemRegularFontOfSize:14.0];
}

#pragma mark - Colors

+ (UIColor *)bottomPanelLineColor
{
    return [UIColor colorWithRed:43/255.0f green:153/255.0f blue:193/255.0f alpha:1.0f];
}

+ (UIColor *)descriptionTextColor
{
    return [UIColor colorWithRed:187.0/255.0 green:221.0/255.0 blue:237.0/255.0 alpha:1.0];
}

+ (UIColor *)bottomPanelBackgroundColor
{
    return [self backgroundColor];
}

+ (UIColor *)swipeToContinueTextColor
{
    return [UIColor colorWithRed:255.0 green:255.0 blue:255.0 alpha:0.3];
}

+ (UIColor *)confirmationLabelColor
{
    return [UIColor colorWithRed:188.0/255.0 green:221.0/255.0 blue:236.0/255.0 alpha:1.0];
}

+ (UIColor *)backgroundColor
{
    return [UIColor colorWithRed:46.0/255.0 green:162.0/255.0 blue:204.0/255.0 alpha:1.0];
}

+ (UIColor *)tosLabelColor
{
    return [self descriptionTextColor];
}

#pragma mark - Helper Methods

+ (void)centerViews:(NSArray *)controls withStartingView:(UIView *)startingView andEndingView:(UIView *)endingView forHeight:(CGFloat)viewHeight
{
    CGFloat heightOfControls = CGRectGetMaxY(endingView.frame) - CGRectGetMinY(startingView.frame);
    CGFloat startingYForCenteredControls = floorf((viewHeight - heightOfControls)/2.0);
    CGFloat offsetToCenter = CGRectGetMinY(startingView.frame) - startingYForCenteredControls;
    
    for (UIControl *control in controls) {
        CGRect frame = control.frame;
        frame.origin.y -= offsetToCenter;
        control.frame = frame;
    }
}

+ (void)configurePageControlTintColors:(UIPageControl *)pageControl
{
    // This only works on iOS6+
    if ([pageControl respondsToSelector:@selector(pageIndicatorTintColor)]) {
        UIColor *currentPageTintColor =  [UIColor colorWithRed:187.0/255.0 green:221.0/255.0 blue:237.0/255.0 alpha:1.0];
        UIColor *pageIndicatorTintColor = [UIColor colorWithRed:38.0/255.0 green:151.0/255.0 blue:197.0/255.0 alpha:1.0];
        pageControl.pageIndicatorTintColor = pageIndicatorTintColor;
        pageControl.currentPageIndicatorTintColor = currentPageTintColor;
    }
}

+ (NSDictionary *)titleAttributesWithColor:(UIColor *)color {
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineHeightMultiple = 0.9;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    NSDictionary *attributes = @{NSFontAttributeName: [WPNUXUtility titleFont],
                                 NSForegroundColorAttributeName: color,
                                 NSParagraphStyleAttributeName: paragraphStyle};
    return attributes;
}

@end
