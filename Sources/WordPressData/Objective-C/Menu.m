#import "Menu.h"
#import "MenuItem.h"
#import "MenuLocation.h"
#import "Blog.h"

NSInteger const MenuDefaultID = -1;

@implementation Menu

@dynamic details;
@dynamic menuID;
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
        if (menu.menuID.integerValue == MenuDefaultID) {
            defaultMenu = menu;
            break;
        }
    }
    return defaultMenu;
}

+ (Menu *)newDefaultMenu:(NSManagedObjectContext *)managedObjectContext
{
    Menu *defaultMenu = [self newMenu:managedObjectContext];
    defaultMenu.menuID = @(MenuDefaultID);
    defaultMenu.name = [self defaultMenuName];
    return defaultMenu;
}

+ (NSString *)defaultMenuName
{
    return NSLocalizedString(@"Default Menu", @"Menu name for the defaut menu that is automatically generated.");
}

- (BOOL)isDefaultMenu
{
    return self.menuID.integerValue == MenuDefaultID;
}

@end
