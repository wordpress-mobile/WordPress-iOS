#import "MenusSelectionItem.h"
#import "Menu.h"
#import "MenuLocation.h"

NSString * const MenusSelectionViewItemChangedSelectedNotification = @"MenusSelectionViewItemChangedSelectedNotification";
NSString * const MenusSelectionViewItemUpdatedItemObjectNotification = @"MenusSelectionViewItemUpdatedItemObjectNotification";

@implementation MenusSelectionItem

+ (MenusSelectionItem *)itemWithMenu:(Menu *)menu
{
    MenusSelectionItem *item = [MenusSelectionItem new];
    item.itemObject = menu;
    return item;
}

+ (MenusSelectionItem *)itemWithLocation:(MenuLocation *)location
{
    MenusSelectionItem *item = [MenusSelectionItem new];
    item.itemObject = location;
    return item;
}

- (void)setSelected:(BOOL)selected
{
    if (_selected != selected) {
        _selected = selected;
        [[NSNotificationCenter defaultCenter] postNotificationName:MenusSelectionViewItemChangedSelectedNotification object:self];
    }
}

- (BOOL)isMenu
{
    return [self.itemObject isKindOfClass:[Menu class]];
}

- (BOOL)isMenuLocation
{
    return [self.itemObject isKindOfClass:[MenuLocation class]];
}

- (NSString *)displayName
{
    NSString *name = nil;
    if ([self isMenu]) {
        Menu *menu = self.itemObject;
        name = menu.name;
    } else  if ([self isMenuLocation]) {
        MenuLocation *location = self.itemObject;
        name = location.details;
    }
    return name;
}

- (void)notifyItemObjectWasUpdated
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MenusSelectionViewItemUpdatedItemObjectNotification object:self];
}

@end

@implementation MenusSelectionAddMenuItem

- (NSString *)displayName
{
    return NSLocalizedString(@"+ Add new menu", @"Menus button text for adding a new menu to a site.");
}

@end
