#import "MenuItemBlankView.h"

@implementation MenuItemBlankView

- (id)init
{
    self = [super init];
    if(self) {
        
        self.iconType = MenuItemsActionableIconAdd;
        self.contentBackgroundColor = [UIColor colorWithWhite:0.98 alpha:1.0];
    }
    
    return self;
}

- (void)setType:(MenuItemBlankViewType)type
{
    if(_type != type) {
        _type = type;
        self.textLabel.text = [self textForType:type];
    }
}

- (NSString *)textForType:(MenuItemBlankViewType)type
{
    NSString *text;
    switch (type) {
        case MenuItemBlankViewAbove:
            text = NSLocalizedString(@"Add menu item above", @"");
            break;
        case MenuItemBlankViewBelow:
            text = NSLocalizedString(@"Add menu item below", @"");
            break;
        case MenuItemBlankViewChild:
            text = NSLocalizedString(@"Add menu item to children", @"");
            break;
        default:
            text = nil;
            break;
    }
    
    return text;
}

@end
