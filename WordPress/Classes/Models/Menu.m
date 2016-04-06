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

+ (NSString *)generateIncrementalNameFromMenus:(NSOrderedSet *)menus
{
    NSInteger highestInteger = 0;
    for (Menu *menu in menus) {
        if (!menu.name.length) {
            continue;
        }
        NSString *nameNumberStr;
        NSScanner *numberScanner = [NSScanner scannerWithString:menu.name];
        NSCharacterSet *characterSet = [NSCharacterSet decimalDigitCharacterSet];
        [numberScanner scanUpToCharactersFromSet:characterSet intoString:NULL];
        [numberScanner scanCharactersFromSet:characterSet intoString:&nameNumberStr];
        
        if ([nameNumberStr integerValue] > highestInteger) {
            highestInteger = [nameNumberStr integerValue];
        }
    }
    highestInteger = highestInteger + 1;
    NSString *menuStr = NSLocalizedString(@"Menu", @"The default text used for filling the name of a menu when creating it.");
    return [NSString stringWithFormat:@"%@ %i", menuStr, highestInteger];
}


@end
