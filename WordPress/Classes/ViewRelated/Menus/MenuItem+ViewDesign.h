#import "MenuItem.h"
#import "Menu+ViewDesign.h"

NS_ASSUME_NONNULL_BEGIN

extern CGFloat const MenusDesignItemIconSize;

/**
 * Design category for providing common values used for drawing, layout, and views involving a MenuItem object.
 */
@interface MenuItem (ViewDesign)

+ (UIImage *)iconImageForItemType:(NSString *)itemType;

@end

NS_ASSUME_NONNULL_END
