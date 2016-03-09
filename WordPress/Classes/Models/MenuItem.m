#import "MenuItem.h"
#import "Menu.h"

NSString * const MenuItemTypePage = @"page";
NSString * const MenuItemTypeCustom = @"custom";
NSString * const MenuItemTypeCategory = @"category";
NSString * const MenuItemTypeTag = @"post_tag";
NSString * const MenuItemTypePost = @"post";
NSString * const MenuItemTypeJetpackTestimonial = @"jetpack-testimonial";
NSString * const MenuItemTypeJetpackPortfolio = @"jetpack-portfolio";
NSString * const MenuItemTypeJetpackComic = @"jetpack-comic";

@implementation MenuItem

@dynamic contentId;
@dynamic details;
@dynamic itemId;
@dynamic linkTarget;
@dynamic linkTitle;
@dynamic name;
@dynamic type;
@dynamic typeFamily;
@dynamic typeLabel;
@dynamic urlStr;
@dynamic menu;
@dynamic children;
@dynamic parent;

+ (NSString *)entityName
{
    return NSStringFromClass([self class]);
}

/* Traverse parent's of the item until we reach nil or a parent object equal to self.
*/
- (BOOL)isDescendantOfItem:(MenuItem *)item
{
    BOOL otherItemIsDescendant = NO;
    MenuItem *ancestor = self.parent;
    while (ancestor) {
        if (ancestor == item) {
            otherItemIsDescendant = YES;
            break;
        }
        ancestor = ancestor.parent;
    };
    return otherItemIsDescendant;
}

@end
