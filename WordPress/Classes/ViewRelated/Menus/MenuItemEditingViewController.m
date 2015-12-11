#import "MenuItemEditingViewController.h"
#import "MenuItem.h"
#import "WPStyleGuide.h"
#import "MenuItemEditingHeaderView.h"
#import "MenuItemEditingFooterView.h"

@interface MenuItemEditingViewController () <MenuItemEditingFooterViewDelegate>

@property (nonatomic, strong) IBOutlet UIStackView *stackView;
@property (nonatomic, strong) IBOutlet MenuItemEditingHeaderView *headerView;
@property (nonatomic, strong) IBOutlet MenuItemEditingFooterView *footerView;

@end

@implementation MenuItemEditingViewController

- (id)initWithItem:(MenuItem *)item
{
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];
    if(self) {
        self.item = item;
    }
    
    return self;
}

- (void)loadView
{
    [super loadView];
    
    self.view.backgroundColor = [WPStyleGuide lightGrey];
    self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    {
        UIEdgeInsets margins = UIEdgeInsetsZero;
        margins.top = [[UIApplication sharedApplication] statusBarFrame].size.height;
        self.stackView.layoutMargins = margins;
        self.stackView.layoutMarginsRelativeArrangement = YES;
    }
    
    self.footerView.delegate = self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
}

#pragma mark - MenuItemEditingFooterViewDelegate

- (void)editingFooterViewDidSelectCancel:(MenuItemEditingFooterView *)footerView
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
