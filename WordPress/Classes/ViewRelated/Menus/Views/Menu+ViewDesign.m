#import "Menu+ViewDesign.h"

CGFloat const MenusDesignDefaultCornerRadius = 4.0;
CGFloat const MenusDesignDefaultContentSpacing = 18.0;

@implementation Menu (ViewDesign)

+ (UIEdgeInsets)viewDefaultDesignInsets
{
    return UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0);
}

@end
