#import "MenuItem.h"
#import "Menu+ViewDesign.h"

extern CGFloat const MenusDesignItemIconSize;

@interface MenuItem (ViewDesign)

+ (NSString *)iconImageNameForItemType:(NSString *)itemType;

@end
