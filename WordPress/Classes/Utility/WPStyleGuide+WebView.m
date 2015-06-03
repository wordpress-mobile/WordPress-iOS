#import "WPStyleGuide+WebView.h"



#pragma mark - WebViewController Styles

@implementation WPStyleGuide (WebView)

+ (UIColor *)webViewModalNavigationBarBackground
{
    return [UIColor whiteColor];
}

+ (UIColor *)webViewModalNavigationBarShadow
{
    return [UIColor colorWithRed:(CGFloat)46/255.0 green:(CGFloat)68/255.0 blue:(CGFloat)83/255.0 alpha:0.15];
}

@end
