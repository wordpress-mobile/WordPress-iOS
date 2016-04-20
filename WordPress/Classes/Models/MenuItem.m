#import "MenuItem.h"
#import "Menu.h"

NSString * const MenuItemTypeIdentifierPage = @"page";
NSString * const MenuItemTypeIdentifierCategory = @"category";
NSString * const MenuItemTypeIdentifierTag = @"post_tag";
NSString * const MenuItemTypeIdentifierPost = @"post";
NSString * const MenuItemTypeIdentifierCustom = @"custom";
NSString * const MenuItemTypeIdentifierJetpackTestimonial = @"jetpack-testimonial";
NSString * const MenuItemTypeIdentifierJetpackPortfolio = @"jetpack-portfolio";

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

/* Return the MenuItemType based on the matching identifier for self.type
 */
- (MenuItemType)itemType
{
    NSString *typeStr = self.type;
    MenuItemType itemType = MenuItemTypeUnknown;
    
    if ([typeStr isEqualToString:MenuItemTypeIdentifierPage]) {
        itemType = MenuItemTypePage;
    } else if ([typeStr isEqualToString:MenuItemTypeIdentifierCustom]) {
        itemType = MenuItemTypeCustom;
    } else if ([typeStr isEqualToString:MenuItemTypeIdentifierCategory]) {
        itemType = MenuItemTypeCategory;
    } else if ([typeStr isEqualToString:MenuItemTypeIdentifierTag]) {
        itemType = MenuItemTypeTag;
    } else if ([typeStr isEqualToString:MenuItemTypeIdentifierPost]) {
        itemType = MenuItemTypePost;
    } else if ([typeStr isEqualToString:MenuItemTypeIdentifierJetpackTestimonial]) {
        itemType = MenuItemTypeJetpackTestimonial;
    } else if ([typeStr isEqualToString:MenuItemTypeIdentifierJetpackPortfolio]) {
        itemType = MenuItemTypeJetpackPortfolio;
    }
    
    return itemType;
}

@end
