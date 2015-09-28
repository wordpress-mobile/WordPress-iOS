#import "MenuItem.h"
#import "Menu.h"

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

@end
