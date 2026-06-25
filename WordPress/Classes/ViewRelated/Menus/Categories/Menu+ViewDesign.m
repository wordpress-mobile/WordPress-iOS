#import "Menu+ViewDesign.h"

CGFloat const MenusDesignStrokeWidth = 0.5;
CGFloat const MenusDesignDefaultCornerRadius = 2.0;
CGFloat const MenusDesignDefaultContentSpacing = 16.0;

@implementation Menu (ViewDesign)

+ (NSDirectionalEdgeInsets)viewDefaultDesignInsets
{
    return NSDirectionalEdgeInsetsMake(10.0, 10.0, 10.0, 10.0);
}

@end
