#import "MenuItemSourceTagView.h"

@implementation MenuItemSourceTagView

- (id)init
{
    self = [super init];
    if(self) {
        
        [self insertSearchBarIfNeeded];
    }
    
    return self;
}

@end
