#import "MenuDetailsStackView.h"
#import "Menu.h"

@interface MenuDetailsStackView ()

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UIButton *trashButton;
@property (nonatomic, weak) IBOutlet UIButton *saveButton;

@end

@implementation MenuDetailsStackView

- (void)setMenu:(Menu *)menu
{
    if(_menu != menu) {
        _menu = menu;
        [self updatedMenu];
    }
}

- (void)updatedMenu
{
    self.titleLabel.text = self.menu.name;
}

@end
