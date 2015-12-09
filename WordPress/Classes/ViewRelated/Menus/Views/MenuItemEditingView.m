#import "MenuItemEditingView.h"
#import "MenuItem.h"
#import "WPStyleGuide.h"

@implementation MenuItemEditingView

- (id)initWithItem:(MenuItem *)item
{
    UINib *nib = [UINib nibWithNibName:NSStringFromClass([self class]) bundle:nil];
    self = [[nib instantiateWithOwner:nil options:nil] firstObject];
    if(self) {
        self.item = item;
    }
    
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.backgroundColor = [WPStyleGuide lightGrey];
}

@end
