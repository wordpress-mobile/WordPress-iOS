#import "MenuLocation.h"
#import "Menu.h"

@implementation MenuLocation

@dynamic defaultState;
@dynamic details;
@dynamic name;
@dynamic blog;
@dynamic menu;

+ (NSString *)entityName
{
    return NSStringFromClass([self class]);
}

@end
