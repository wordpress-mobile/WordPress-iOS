#import "WPStyleGuide+WebView.h"



#pragma mark - WebViewController Styles

@implementation WPStyleGuide (WebView)

+ (UIColor *)webViewModalNavigationBarBackground
{
    return [UIColor whiteColor];
}

+ (UIColor *)webViewModalNavigationBarShadow
{
    return [UIColor colorWithRed:46.0/255.0 green:68.0/255.0 blue:83.0/255.0 alpha:0.15];
}

@end
