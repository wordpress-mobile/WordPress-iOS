#import "Menu.h"
#import "MenuItem.h"
#import "MenuLocation.h"
#import "Blog.h"

NSString * const MenuDefaultID = @"0";

@implementation Menu

@dynamic details;
@dynamic menuId;
@dynamic name;
@dynamic items;
@dynamic locations;
@dynamic blog;

+ (NSString *)entityName
{
    return NSStringFromClass([self class]);
}

+ (Menu *)newMenu:(NSManagedObjectContext *)managedObjectContext
{
    Menu *newMenu = [NSEntityDescription insertNewObjectForEntityForName:[Menu entityName] inManagedObjectContext:managedObjectContext];
    return newMenu;
}

+ (Menu *)defaultMenuForBlog:(Blog *)blog
{
    Menu *defaultMenu = nil;
    for (Menu *menu in blog.menus) {
        if ([menu.menuId isEqualToString:MenuDefaultID]) {
            defaultMenu = menu;
            break;
        }
    }
    return defaultMenu;
}

+ (Menu *)newDefaultMenu:(NSManagedObjectContext *)managedObjectContext
{
    // Create a new default menu.
    Menu *defaultMenu = [self newMenu:managedObjectContext];
    defaultMenu.menuId = MenuDefaultID;
    defaultMenu.name = [self defaultMenuName];
    return defaultMenu;
}

+ (NSString *)defaultMenuName
{
    return NSLocalizedString(@"Default Menu", @"Menu name for the defaut menu that is automatically generated.");
}

@end
