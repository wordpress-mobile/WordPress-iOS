#import "MenusViewController.h"

@interface MenusViewController ()

@end

@implementation MenusViewController

+ (MenusViewController *)newMenusViewController
{
    MenusViewController *controller = [[MenusViewController alloc] initWithNibName:NSStringFromClass([self class]) bundle:nil];
    return controller;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

@end
