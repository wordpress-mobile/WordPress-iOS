#import "Menu.h"
#import "MenuItem.h"
#import "MenuLocation.h"

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

@end
