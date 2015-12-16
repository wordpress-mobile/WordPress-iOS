#import "MenuItemEditingViewController.h"
#import "MenuItem.h"
#import "WPStyleGuide.h"
#import "MenuItemEditingHeaderView.h"
#import "MenuItemEditingFooterView.h"
#import "MenuItemSourceView.h"
#import "MenuItemEditingTypeView.h"
#import "MenuItemSourceTypeSelectionView.h"

static CGFloat const MenuItemEditingFooterViewDefaultHeight = 60.0;
static CGFloat const MenuItemEditingFooterViewCompactHeight = 46.0;

@interface MenuItemEditingViewController () <MenuItemSourceViewDelegate, MenuItemEditingFooterViewDelegate>

@property (nonatomic, strong) IBOutlet UIStackView *baseStackView;
@property (nonatomic, strong) IBOutlet UIStackView *itemEditingStackView;
@property (nonatomic, strong) IBOutlet UIScrollView *itemEditingScrollView;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *stackViewBottomConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *footerViewHeightConstraint;

@property (nonatomic, strong) IBOutlet MenuItemEditingHeaderView *headerView;
@property (nonatomic, strong) IBOutlet MenuItemEditingFooterView *footerView;
@property (nonatomic, strong) IBOutlet MenuItemEditingTypeView *typeSelectionView;
@property (nonatomic, strong) IBOutlet MenuItemSourceView *sourceView;
@property (nonatomic, strong) IBOutlet MenuItemSourceTypeSelectionView *selectionButton;

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
    self.baseStackView.translatesAutoresizingMaskIntoConstraints = NO;
    self.itemEditingStackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.headerView.item = self.item;
    self.sourceView.item = self.item;
    self.sourceView.delegate = self;
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

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.itemEditingScrollView.contentSize = self.itemEditingStackView.frame.size;
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
    if([self shouldDisplayForCompactWidth]) {
        [self setDisplayForCompactWidth];
    }else {
        [self setDisplayForRegularWidth];
    }
}

- (BOOL)shouldDisplayForCompactWidth
{
    if(IS_IPAD) {
        return NO;
    }
    return (self.view.frame.size.width <= self.view.frame.size.height);
}

- (void)setDisplayForRegularWidth
{
    self.typeSelectionView.hidden = NO;
    self.selectionButton.hidden = YES;
    
    if(IS_IPHONE) {
        // iPad has much more room to work with than iPhone
        self.footerViewHeightConstraint.constant = MenuItemEditingFooterViewCompactHeight;
    }
}

- (void)setDisplayForCompactWidth
{
    self.typeSelectionView.hidden = YES;
    self.selectionButton.hidden = NO;
    self.footerViewHeightConstraint.constant = MenuItemEditingFooterViewDefaultHeight;
}

#pragma mark - MenuItemSourceViewDelegate

- (void)sourceViewDidBeginTyping:(MenuItemSourceView *)sourceView
{

}

- (void)sourceViewDidEndTyping:(MenuItemSourceView *)sourceView
{

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
