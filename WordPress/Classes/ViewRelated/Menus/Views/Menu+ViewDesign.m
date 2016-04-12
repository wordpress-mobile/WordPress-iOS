#import "Menu+ViewDesign.h"

CGFloat const MenusDesignStrokeWidth = 1.0;
CGFloat const MenusDesignDefaultCornerRadius = 4.0;
CGFloat const MenusDesignDefaultContentSpacing = 14.0;

@implementation Menu (ViewDesign)

+ (UIEdgeInsets)viewDefaultDesignInsets
{
    return UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0);
}

@end
