#import "MenuItem+ViewDesign.h"

CGFloat const MenusDesignItemIconSize = 18.0;

@implementation MenuItem (ViewDesign)

+ (NSString *)iconImageNameForItemType:(NSString *)itemType
{
    NSString *imageName = nil;
    
    if ([itemType isEqualToString:MenuItemTypePage]) {
        imageName = @"gridicons-pages";
    } else if ([itemType isEqualToString:MenuItemTypeCustom]) {
        imageName = @"gridicons-link";
    } else if ([itemType isEqualToString:MenuItemTypeCategory]) {
        imageName = @"gridicons-folder";
    } else if([itemType isEqualToString:MenuItemTypeTag]) {
        imageName = @"gridicons-tag";
    }
    
    return imageName ?: @"gridicons-posts";
}

@end
