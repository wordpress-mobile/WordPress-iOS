#import "MenuItemSourcePostView.h"

@implementation MenuItemSourcePostView

- (id)init
{
    self = [super init];
    if(self) {
        
        [self insertSearchBarIfNeeded];
    }
    
    return self;
}

@end
