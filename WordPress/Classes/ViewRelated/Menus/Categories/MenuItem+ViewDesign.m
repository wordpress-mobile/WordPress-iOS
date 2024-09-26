#import "MenuItem+ViewDesign.h"

@import Gridicons;

CGFloat const MenusDesignItemIconSize = 18.0;

@implementation MenuItem (ViewDesign)

+ (UIImage *)iconImageForItemType:(NSString *)itemType
{
    UIImage *image = nil;

    if ([itemType isEqualToString:MenuItemTypePage]) {
        image = [UIImage gridiconOfType:GridiconTypePages];
    } else if ([itemType isEqualToString:MenuItemTypeCustom]) {
        image = [UIImage gridiconOfType:GridiconTypeLink];
    } else if ([itemType isEqualToString:MenuItemTypeCategory]) {
        image = [UIImage gridiconOfType:GridiconTypeFolder];
    } else if ([itemType isEqualToString:MenuItemTypeTag]) {
        image = [UIImage gridiconOfType:GridiconTypeTag];
    }

    return image ?: [UIImage gridiconOfType:GridiconTypePosts];
}

@end
