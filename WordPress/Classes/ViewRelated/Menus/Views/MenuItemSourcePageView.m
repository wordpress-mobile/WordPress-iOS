#import "MenuItemSourcePageView.h"

@implementation MenuItemSourcePageView

- (id)init
{
    self = [super init];
    if(self) {
        
        [self insertSearchBarIfNeeded];
        
        // samples
        {
            MenuItemSourceOption *option = [[MenuItemSourceOption alloc] init];
            option.title = @"Home";
            option.badgeTitle = @"SITE";
            option.selected = YES;
            
            [self insertSourceOption:option];
        }
        {
            MenuItemSourceOption *option = [[MenuItemSourceOption alloc] init];
            option.title = @"About";
            [self insertSourceOption:option];
        }
        {
            MenuItemSourceOption *option = [[MenuItemSourceOption alloc] init];
            option.title = @"Contact";
            [self insertSourceOption:option];
        }
        {
            MenuItemSourceOption *option = [[MenuItemSourceOption alloc] init];
            option.title = @"Work";
            [self insertSourceOption:option];
        }
    }
    
    return self;
}

@end
