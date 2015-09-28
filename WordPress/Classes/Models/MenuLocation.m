#import "MenuLocation.h"
#import "Menu.h"

@implementation MenuLocation

@dynamic defaultState;
@dynamic details;
@dynamic name;
@dynamic menus;
@dynamic blog;

+ (NSString *)entityName
{
    return NSStringFromClass([self class]);
}

@end
