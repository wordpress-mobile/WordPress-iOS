#import "MenuItem.h"
#import "Menu+ViewDesign.h"

extern CGFloat const MenusDesignItemIconSize;

/**
 * Design category for providing common values used for drawing, layout, and views involving a MenuItem object.
 */
@interface MenuItem (ViewDesign)

+ (UIImage *)iconImageForItemType:(NSString *)itemType;

@end
