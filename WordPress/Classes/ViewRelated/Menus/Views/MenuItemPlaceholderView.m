#import "MenuItemPlaceholderView.h"

@implementation MenuItemPlaceholderView

- (id)init
{
    self = [super init];
    if(self) {
        
        self.iconType = MenuItemsActionableIconAdd;
        self.contentBackgroundColor = [UIColor colorWithWhite:0.98 alpha:1.0];
    }
    
    return self;
}

- (void)setType:(MenuItemPlaceholderViewType)type
{
    if(_type != type) {
        _type = type;
        self.textLabel.text = [self textForType:type];
    }
}

- (NSString *)textForType:(MenuItemPlaceholderViewType)type
{
    NSString *text;
    switch (type) {
        case MenuItemPlaceholderViewAbove:
            text = NSLocalizedString(@"Add menu item above", @"");
            break;
        case MenuItemPlaceholderViewBelow:
            text = NSLocalizedString(@"Add menu item below", @"");
            break;
        case MenuItemPlaceholderViewChild:
            text = NSLocalizedString(@"Add menu item to children", @"");
            break;
        default:
            text = nil;
            break;
    }
    
    return text;
}

@end
