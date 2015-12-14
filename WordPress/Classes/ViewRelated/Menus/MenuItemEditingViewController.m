#import "MenuItemEditingViewController.h"
#import "MenuItem.h"
#import "WPStyleGuide.h"
#import "MenuItemEditingHeaderView.h"
#import "MenuItemEditingFooterView.h"
#import "MenuItemSourceView.h"
#import "MenuItemEditingTypeView.h"

@interface MenuItemEditingViewController () <MenuItemEditingFooterViewDelegate>

@property (nonatomic, strong) IBOutlet UIStackView *stackView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *stackViewBottomConstraint;
@property (nonatomic, strong) IBOutlet MenuItemEditingHeaderView *headerView;
@property (nonatomic, strong) IBOutlet MenuItemEditingFooterView *footerView;
@property (nonatomic, strong) IBOutlet MenuItemEditingTypeView *typeSelectionView;
@property (nonatomic, strong) IBOutlet MenuItemSourceView *sourceView;

@property (nonatomic, assign) BOOL observesKeyboardChanges;

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
    
    self.view.backgroundColor = [WPStyleGuide lightGrey];
    self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.headerView.item = self.item;
    self.footerView.item = self.item;
    self.footerView.delegate = self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if(self.modalPresentationStyle == UIModalPresentationFormSheet) {
        
        self.view.superview.layer.cornerRadius = 0.0;
        self.headerView.shouldProvidePaddingForStatusBar = NO;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if(self.modalPresentationStyle == UIModalPresentationFormSheet) {
        
        self.view.superview.layer.cornerRadius = 0.0;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHideNotification:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowNotification:) name:UIKeyboardWillShowNotification object:nil];
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

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    [self updateTypeSelectionViewDisplay];
}

- (void)updateTypeSelectionViewDisplay
{
    if(self.view.frame.size.width >= self.view.frame.size.height) {
        self.typeSelectionView.hidden = NO;
    }else {
        self.typeSelectionView.hidden = YES;
    }
}

#pragma mark - MenuItemEditingFooterViewDelegate

- (void)editingFooterViewDidSelectCancel:(MenuItemEditingFooterView *)footerView
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    
}

#pragma mark - notifications

- (void)updateWithKeyboardNotification:(NSNotification *)notification
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
    
    NSTimeInterval duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions options = [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
        
        [self.view layoutIfNeeded];
        
    } completion:nil];
}

- (void)keyboardWillHideNotification:(NSNotification *)notification
{
    self.observesKeyboardChanges = NO;
    
    self.stackViewBottomConstraint.constant = 0;
    [self.view layoutIfNeeded];
}

- (void)keyboardWillShowNotification:(NSNotification *)notification
{
    self.observesKeyboardChanges = YES;
    [self updateWithKeyboardNotification:notification];
}

- (void)keyboardWillChangeFrameNotification:(NSNotification *)notification
{
    if(self.observesKeyboardChanges) {
        [self updateWithKeyboardNotification:notification];
    }
}

@end
