#import "MenuItemEditingHeaderView.h"
#import "WPStyleGuide.h"

@implementation MenuItemEditingHeaderView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.backgroundColor = [WPStyleGuide mediumBlue];
}

@end
