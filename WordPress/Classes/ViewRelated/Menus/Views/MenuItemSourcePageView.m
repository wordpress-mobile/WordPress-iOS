#import "MenuItemSourcePageView.h"

@implementation MenuItemSourcePageView

- (id)init
{
    self = [super init];
    if(self) {
        
        [self insertSearchBarIfNeeded];
        
        // samples
        {
            MenuItemSource *source = [[MenuItemSource alloc] init];
            source.title = @"Home";
            source.badgeTitle = @"SITE";
            source.selected = YES;
            
            [self insertSource:source];
        }
        {
            MenuItemSource *source = [[MenuItemSource alloc] init];
            source.title = @"About";
            [self insertSource:source];
        }
        {
            MenuItemSource *source = [[MenuItemSource alloc] init];
            source.title = @"Contact";
            [self insertSource:source];
        }
        {
            MenuItemSource *source = [[MenuItemSource alloc] init];
            source.title = @"Work";
            [self insertSource:source];
        }
        
        [self.tableView reloadData];
    }
    
    return self;
}

@end
