#import "MenuItem+ViewDesign.h"

@import Gridicons;

CGFloat const MenusDesignItemIconSize = 18.0;

@implementation MenuItem (ViewDesign)

+ (UIImage *)iconImageForItemType:(NSString *)itemType
{
    UIImage *image = nil;

    if ([itemType isEqualToString:MenuItemType.page]) {
        image = [UIImage gridiconOfType:GridiconTypePages];
    } else if ([itemType isEqualToString:MenuItemType.custom]) {
        image = [UIImage gridiconOfType:GridiconTypeLink];
    } else if ([itemType isEqualToString:MenuItemType.category]) {
        image = [UIImage gridiconOfType:GridiconTypeFolder];
    } else if ([itemType isEqualToString:MenuItemType.tag]) {
        image = [UIImage gridiconOfType:GridiconTypeTag];
    }

    return image ?: [UIImage gridiconOfType:GridiconTypePosts];
}

@end
