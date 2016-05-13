#import "Menu.h"

extern CGFloat const MenusDesignStrokeWidth;
extern CGFloat const MenusDesignDefaultCornerRadius;
extern CGFloat const MenusDesignDefaultContentSpacing;

/**
 * Design category for providing common values used for drawing, layout, and views involving a Menu object.
 */
@interface Menu (ViewDesign)

+ (UIEdgeInsets)viewDefaultDesignInsets;

@end
