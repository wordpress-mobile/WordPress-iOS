#import "MenuItemSourceView.h"
#import "MenusDesign.h"

@interface MenuItemSourceView ()

@property (nonatomic, strong) IBOutlet UIStackView *stackView;
@property (nonatomic, strong) UIView *searchFieldContainerView;
@property (nonatomic, strong) UITextField *searchField;

@end

@implementation MenuItemSourceView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = [UIColor whiteColor];
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
    {
        UIEdgeInsets margins = UIEdgeInsetsZero;
        margins.top = MenusDesignDefaultContentSpacing;
        margins.left = 40.0;
        margins.right = margins.left;
        margins.bottom = MenusDesignDefaultContentSpacing;
        self.stackView.layoutMargins = margins;
        self.stackView.layoutMarginsRelativeArrangement = YES;
    }
}

@end
