#import "MenuDetailsView.h"
#import "Menu.h"
#import "WPStyleGuide.h"
#import "UIColor+Helpers.h"
#import "WPFontManager.h"
#import "MenusActionButton.h"

@interface MenuDetailsView ()

@property (nonatomic, weak) IBOutlet UIStackView *stackView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet MenusActionButton *trashButton;
@property (nonatomic, weak) IBOutlet MenusActionButton *saveButton;

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
    self.titleLabel.textColor = [UIColor colorWithWhite:0.25 alpha:1.0];
    
    self.trashButton.backgroundDrawColor = [UIColor whiteColor];
    [self.trashButton setImage:[self.trashButton templatedIconImageNamed:@"icon-menus-trash"] forState:UIControlStateNormal];
    [self.trashButton addTarget:self action:@selector(pushed) forControlEvents:UIControlEventTouchUpInside];
    
    self.saveButton.backgroundDrawColor = [WPStyleGuide mediumBlue];
    [self.saveButton setTitle:NSLocalizedString(@"Save", @"Menus save button title") forState:UIControlStateNormal];
    [self.saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
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

- (void)pushed
{
    
}

@end
