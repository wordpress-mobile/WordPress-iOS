#import "MenuItem.h"
#import "Menu+ViewDesign.h"

extern CGFloat const MenusDesignItemIconSize;

@interface MenuItem (ViewDesign)

+ (UIImage *)iconImageForItemType:(NSString *)itemType;

@end
