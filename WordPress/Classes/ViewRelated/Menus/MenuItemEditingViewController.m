#import "MenuItemEditingViewController.h"
#import "MenuItem.h"
#import "WPStyleGuide.h"
#import "MenuItemEditingHeaderView.h"
#import "MenuItemEditingFooterView.h"
#import "MenuItemSourceView.h"

@interface MenuItemEditingViewController () <MenuItemEditingFooterViewDelegate>

@property (nonatomic, strong) IBOutlet UIStackView *stackView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *stackViewBottomConstraint;
@property (nonatomic, strong) IBOutlet MenuItemEditingHeaderView *headerView;
@property (nonatomic, strong) IBOutlet MenuItemEditingFooterView *footerView;
@property (nonatomic, strong) IBOutlet MenuItemSourceView *sourceView;

@end

@implementation MenuItemEditingViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

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
    
    self.stackView.layoutMarginsRelativeArrangement = YES;
    self.view.backgroundColor = [WPStyleGuide lightGrey];
    self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.headerView.item = self.item;
    self.footerView.item = self.item;
    self.footerView.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrameNotification:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - MenuItemEditingFooterViewDelegate

- (void)editingFooterViewDidSelectCancel:(MenuItemEditingFooterView *)footerView
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - notifications

- (void)keyboardWillChangeFrameNotification:(NSNotification *)notification
{
    CGRect frame = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    frame = [self.view.window convertRect:frame toView:self.view];
    
    CGFloat constraintConstant = self.stackViewBottomConstraint.constant;
    
    if(frame.origin.y > self.view.frame.size.height) {
        constraintConstant = 0.0;
    }else {
        constraintConstant = self.view.frame.size.height - frame.origin.y;
    }

    [self.view layoutIfNeeded];
    self.stackViewBottomConstraint.constant = constraintConstant;
    
    [UIView animateWithDuration:[[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue] animations:^{
        [self.view layoutIfNeeded];
    }];
}

@end
