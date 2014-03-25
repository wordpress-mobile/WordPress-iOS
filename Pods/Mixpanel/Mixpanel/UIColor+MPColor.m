#import "UIColor+MPColor.h"

@implementation UIColor (MPColor)

+ (UIColor *)mp_applicationPrimaryColor
{

    UIColor *color;

    // First try and find the color of the UINavigationBar of the top UINavigationController that is showing now.
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    UINavigationController *topNavigationController = nil;

    do {
        if ([rootViewController isKindOfClass:[UINavigationController class]]) {
            topNavigationController = (UINavigationController *)rootViewController;
        } else if (rootViewController.navigationController) {
            topNavigationController = rootViewController.navigationController;
        }
    } while ((rootViewController = rootViewController.presentedViewController));

    if (topNavigationController) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
        if ([[topNavigationController navigationBar] respondsToSelector:@selector(barTintColor)]) {
            color = [[topNavigationController navigationBar] barTintColor];
        } else {
            color = [topNavigationController navigationBar].tintColor;
        }
#else
        color = [topNavigationController navigationBar].tintColor;
#endif
    }

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    // Then try and use the UINavigationBar default color for the app
    if (!color && [[UINavigationBar appearance] respondsToSelector:@selector(barTintColor)]) {
        color = [[UINavigationBar appearance] barTintColor];
    }

    // Or the UITabBar default color
    if (!color && [[UITabBar appearance] respondsToSelector:@selector(barTintColor)]) {
        color = [[UITabBar appearance] barTintColor];
    }
#endif

    return color;
}

+ (UIColor *)mp_lightEffectColor
{
    return [UIColor colorWithWhite:1.0f alpha:0.3f];
}

+ (UIColor *)mp_extraLightEffectColor
{
    return [UIColor colorWithWhite:0.97f alpha:0.82f];
}

+ (UIColor *)mp_darkEffectColor
{
    return [UIColor colorWithWhite:0.11f alpha:0.73f];
}

- (UIColor *)colorWithSaturationComponent:(CGFloat) saturation
{
    UIColor *newColor;
    CGFloat h, s, b, a;
    if ([self getHue:&h saturation:&s brightness:&b alpha:&a]) {
        newColor = [UIColor colorWithHue:h saturation:saturation brightness:b alpha:a];
    }
    return newColor;
}

@end
