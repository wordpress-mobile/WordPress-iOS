#import "MenuItem+ViewDesign.h"

@import Gridicons;

CGFloat const MenusDesignItemIconSize = 18.0;

@implementation MenuItem (ViewDesign)

+ (UIImage *)iconImageForItemType:(NSString *)itemType
{
    UIImage *image = nil;
    
    if ([itemType isEqualToString:MenuItemTypePage]) {
        image = [Gridicon iconOfType:GridiconTypePages];
    } else if ([itemType isEqualToString:MenuItemTypeCustom]) {
        image = [Gridicon iconOfType:GridiconTypeLink];
    } else if ([itemType isEqualToString:MenuItemTypeCategory]) {
        image = [Gridicon iconOfType:GridiconTypeFolder];
    } else if ([itemType isEqualToString:MenuItemTypeTag]) {
        image = [Gridicon iconOfType:GridiconTypeTag];
    }
    
    return image ?: [Gridicon iconOfType:GridiconTypePosts];
}

@end
