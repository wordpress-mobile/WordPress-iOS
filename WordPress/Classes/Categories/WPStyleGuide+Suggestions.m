#import "WPStyleGuide+Suggestions.h"

@implementation WPStyleGuide (Suggestions)

+ (UIColor *)suggestionsHeaderSmoke
{
    return [UIColor colorWithDynamicProvider:^(UITraitCollection *traitCollection) {
        if (traitCollection.userInterfaceStyle ==  UIUserInterfaceStyleDark) {
            return [UIColor colorWithRed:0. green:0. blue:0. alpha:0.7];
        } else {
            return [UIColor colorWithRed:0. green:0. blue:0. alpha:0.3];
        }
    }];
}

+ (UIColor *)suggestionsSeparatorSmoke
{
    return [UIColor colorWithRed:0. green:0. blue:0. alpha:0.1];
}

@end
