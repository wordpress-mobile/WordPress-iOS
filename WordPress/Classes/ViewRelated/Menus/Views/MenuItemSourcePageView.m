#import "MenuItemSourcePageView.h"

@implementation MenuItemSourcePageView

- (id)init
{
    self = [super init];
    if(self) {
        
        [self insertSearchBarIfNeeded];
    }
    
    return self;
}

@end
