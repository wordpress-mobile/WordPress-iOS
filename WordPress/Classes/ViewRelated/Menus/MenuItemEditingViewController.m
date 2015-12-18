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

@property (nonatomic, strong) IBOutlet UIStackView *stackView;
@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet UIStackView *scrollingStackView;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *stackViewBottomConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *footerViewHeightConstraint;

@property (nonatomic, strong) IBOutlet MenuItemEditingHeaderView *headerView;
@property (nonatomic, strong) IBOutlet MenuItemEditingFooterView *footerView;
@property (nonatomic, strong) IBOutlet MenuItemEditingTypeView *typeSelectionView;
@property (nonatomic, strong) IBOutlet MenuItemSourceView *sourceView;
@property (nonatomic, strong) IBOutlet MenuItemSourceTypeSelectionView *selectionButton;

@property (nonatomic, assign) BOOL observesKeyboardChanges;
@property (nonatomic, assign) BOOL sourceViewIsTyping;

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
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.backgroundColor = self.view.backgroundColor;
    self.scrollView.clipsToBounds = NO;
    
    self.headerView.item = self.item;
    self.sourceView.item = self.item;
    self.sourceView.delegate = self;
    self.footerView.item = self.item;
    self.footerView.delegate = self;
    
    [self.stackView bringSubviewToFront:self.headerView];
    [self updateSourceAndEditingViewsAvailability:NO];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.scrollView.contentSize = self.scrollingStackView.frame.size;
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

- (BOOL)prefersStatusBarHidden
{
    return self.headerView.hidden;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    [self updateForLayoutChange];
}

- (BOOL)shouldDisplayForCompactWidth
{
    if(IS_IPAD) {
        return NO;
    }
    
    BOOL horizontallyCompact = [self.traitCollection containsTraitsInCollection:[UITraitCollection traitCollectionWithHorizontalSizeClass:UIUserInterfaceSizeClassCompact]];
    
    if(horizontallyCompact) {
        
        if([self.traitCollection containsTraitsInCollection:[UITraitCollection traitCollectionWithVerticalSizeClass:UIUserInterfaceSizeClassCompact]]) {
            horizontallyCompact = NO;
        }
    }
    
    return horizontallyCompact;
}

#pragma mark - arrangedSubViews

- (void)updateForLayoutChange
{
    if([self shouldDisplayForCompactWidth]) {
        [self updateForCompactWidthLayout];
    }else {
        [self updateForExtendedWidthLayout];
    }
    
    [self setNeedsStatusBarAppearanceUpdate];
    [self.stackView layoutIfNeeded];
}

- (void)updateForCompactWidthLayout
{
    if(self.sourceViewIsTyping) {
        
        if(!self.headerView.hidden) {
            self.headerView.hidden = YES;
            self.headerView.alpha = 0.0;
        }
        
    }else {
        
        if(self.headerView.hidden) {
            self.headerView.hidden = NO;
            self.headerView.alpha = 1.0;
            [self.headerView setNeedsDisplay];
        }
    }
    
    if(self.selectionButton.hidden) {
        self.selectionButton.hidden = NO;
        self.selectionButton.alpha = 1.0;
    }
    
    if(!self.typeSelectionView.hidden) {
        self.typeSelectionView.hidden = YES;
        self.typeSelectionView.alpha = 0.0;
    }
    
    if(IS_IPHONE) {
        self.footerViewHeightConstraint.constant = MenuItemEditingFooterViewDefaultHeight;
    }
}

- (void)updateForExtendedWidthLayout
{
    if(self.sourceViewIsTyping) {
        
        if(!self.headerView.hidden) {
            self.headerView.hidden = YES;
            self.headerView.alpha = 0.0;
        }
        
        if(!self.typeSelectionView.hidden) {
            self.typeSelectionView.hidden = YES;
            self.typeSelectionView.alpha = 0.0;
        }
        
    }else {
        
        if(self.headerView.hidden) {
            self.headerView.hidden = NO;
            self.headerView.alpha = 1.0;
            [self.headerView setNeedsDisplay];
        }
        
        if(self.typeSelectionView.hidden) {
            self.typeSelectionView.hidden = NO;
            self.typeSelectionView.alpha = 1.0;
        }
    }
    
    if(!self.selectionButton.hidden) {
        self.selectionButton.hidden = YES;
        self.selectionButton.alpha = 0.0;
    }
    
    if(IS_IPHONE) {
        self.footerViewHeightConstraint.constant = MenuItemEditingFooterViewCompactHeight;
    }
}

- (void)updateSourceAndEditingViewsAvailability:(BOOL)animated
{
    if(animated) {
        
        [self.stackView layoutIfNeeded];
        [UIView animateWithDuration:0.20 animations:^{
            
            [self updateForLayoutChange];
        }];
        
    }else {
        [self updateForLayoutChange];
    }
}

#pragma mark - MenuItemSourceViewDelegate

- (void)sourceViewDidBeginTyping:(MenuItemSourceView *)sourceView
{
    self.sourceViewIsTyping = YES;
    [self updateSourceAndEditingViewsAvailability:YES];
}

- (void)sourceViewDidEndTyping:(MenuItemSourceView *)sourceView
{
    self.sourceViewIsTyping = NO;
    [self updateSourceAndEditingViewsAvailability:YES];
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
