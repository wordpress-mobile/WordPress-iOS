#import "MenuDetailsView.h"
#import "Menu.h"
#import "WPStyleGuide.h"
#import "UIColor+Helpers.h"
#import "WPFontManager.h"

@interface MenuDetailsView ()

@property (nonatomic, weak) IBOutlet UIStackView *stackView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UIButton *trashButton;
@property (nonatomic, weak) IBOutlet UIButton *saveButton;

@end

@implementation MenuDetailsView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self setupStyling];
}

- (void)setupStyling
{
    self.backgroundColor = [UIColor clearColor];
    self.titleLabel.font = [WPFontManager openSansLightFontOfSize:22.0];
    self.titleLabel.textColor = [UIColor colorWithWhite:0.25 alpha:1.0];
}

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
