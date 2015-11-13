#import "MenuItemView.h"
#import "MenuItem.h"
#import "WPStyleGuide.h"
#import "MenusDesign.h"

@implementation MenuItemView

- (void)setItem:(MenuItem *)item
{
    if(_item != item) {
        _item = item;
    }
}

- (UIColor *)highlightedColor
{
    return [UIColor colorWithWhite:0.985 alpha:1.0];
}

@end
