#import "MenusItemsHeaderView.h"
#import "WPStyleGuide.h"

@interface MenusItemsHeaderView ()

@property (nonatomic, strong) UIView *nameLabel;
@property (nonatomic, strong) UIView *trashButton;
@property (nonatomic, strong) UIView *saveButton;

@end

@implementation MenusItemsHeaderView

+ (MenusItemsHeaderView *)headerViewFromNib
{
    return [[[UINib nibWithNibName:NSStringFromClass([self class]) bundle:nil] instantiateWithOwner:self options:nil] firstObject];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = [WPStyleGuide greyLighten30];
}

- (void)setMenu:(Menu *)menu
{
    if(_menu != menu) {
        _menu = menu;
    }
}

@end
