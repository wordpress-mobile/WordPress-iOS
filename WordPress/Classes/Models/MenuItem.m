#import "MenuItem.h"
#import "Menu.h"
#import "PostType.h"
#import "Blog.h"

NSString * const MenuItemTypePage = @"page";
NSString * const MenuItemTypeCustom = @"custom";
NSString * const MenuItemTypeCategory = @"category";
NSString * const MenuItemTypeTag = @"post_tag";
NSString * const MenuItemTypePost = @"post";
NSString * const MenuItemTypeJetpackTestimonial = @"jetpack-testimonial";
NSString * const MenuItemTypeJetpackPortfolio = @"jetpack-portfolio";
NSString * const MenuItemTypeJetpackComic = @"jetpack-comic";

NSString * const MenuItemLinkTargetBlank = @"_blank";
NSString * const MenuItemDefaultLinkTitle = @"New Item";

@implementation MenuItem

@dynamic contentID;
@dynamic details;
@dynamic itemID;
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
@dynamic classes;

+ (NSString *)entityName
{
    return NSStringFromClass([self class]);
}

+ (NSString *)labelForType:(NSString *)itemType blog:(nullable Blog *)blog
{
    NSString *label = nil;
    if ([itemType isEqualToString:MenuItemTypePage]) {
        label = NSLocalizedString(@"Page", @"Menu item label for linking a page.");
    } else if ([itemType isEqualToString:MenuItemTypePost]) {
        label = NSLocalizedString(@"Post", @"Menu item label for linking a post.");
    } else if ([itemType isEqualToString:MenuItemTypeCustom]) {
        label = NSLocalizedString(@"Link", @"Menu item label for linking a custom source URL.");
    } else if ([itemType isEqualToString:MenuItemTypeCategory]) {
        label = NSLocalizedString(@"Category", @"Menu item label for linking a specific category.");
    } else if ([itemType isEqualToString:MenuItemTypeTag]) {
        label = NSLocalizedString(@"Tag", @"Menu item label for linking a specific tag.");
    } else if ([itemType isEqualToString:MenuItemTypeJetpackTestimonial]) {
        label = NSLocalizedString(@"Testimonials", @"Menu item label for linking a testimonial post.");
    } else if ([itemType isEqualToString:MenuItemTypeJetpackPortfolio]) {
        label = NSLocalizedString(@"Projects", @"Menu item label for linking a project page.");
    } else if ([itemType isEqualToString:MenuItemTypeJetpackComic]) {
        label = NSLocalizedString(@"Comics", @"Menu item label for linking a comic page.");
    } else if (blog) {
        // Check any custom postTypes that may have a label for the itemType.
        for (PostType *postType in blog.postTypes) {
            // If the postType name matches, use its label.
            if ([postType.name isEqualToString:itemType]) {
                label = postType.label;
                break;
            }
        }
    }
    return label;
}

+ (NSString *)defaultItemNameLocalized
{
    return NSLocalizedString(@"New item", @"Menu item title text used as default when creating a new menu item.");
}

/**
 Traverse parent's of the item until we reach nil or a parent object equal to self.
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

/**
 Traverse the orderedItems for parent items equal to self or that are a descendant of self (a child of a child).
 */
- (MenuItem *)lastDescendantInOrderedItems:(NSOrderedSet *)orderedItems
{
    MenuItem *lastChildItem = nil;
    NSUInteger parentIndex = [orderedItems indexOfObject:self];
    for (NSUInteger i = parentIndex + 1; i < orderedItems.count; i++) {
        MenuItem *child = [orderedItems objectAtIndex:i];
        if (child.parent == self) {
            lastChildItem = child;
        }
        if (![lastChildItem isDescendantOfItem:self]) {
            break;
        }
    }
    return lastChildItem;
}

- (BOOL)nameIsEmptyOrDefault
{
    return self.name.length == 0 || [self.name isEqualToString:[MenuItem defaultItemNameLocalized]];
}

@end
