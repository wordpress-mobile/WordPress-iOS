#import "MenuItemEditingViewController.h"
#import "MenuItem.h"
#import "WPStyleGuide.h"
#import "MenuItemEditingHeaderView.h"
#import "MenuItemEditingFooterView.h"
#import "MenuItemSourceView.h"
#import "MenuItemTypeSelectionView.h"

static CGFloat const MenuItemEditingFooterViewDefaultHeight = 60.0;
static CGFloat const MenuItemEditingFooterViewCompactHeight = 46.0;

@interface MenuItemEditingViewController () <MenuItemSourceViewDelegate, MenuItemEditingFooterViewDelegate, MenuItemTypeSelectionViewDelegate>

@property (nonatomic, strong) IBOutlet UIStackView *stackView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *stackViewBottomConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *footerViewHeightConstraint;

@property (nonatomic, strong) IBOutlet MenuItemEditingHeaderView *headerView;
@property (nonatomic, strong) IBOutlet MenuItemEditingFooterView *footerView;
@property (nonatomic, strong) IBOutlet MenuItemTypeSelectionView *typeView;
@property (nonatomic, strong) IBOutlet MenuItemSourceView *sourceView;
@property (nonatomic, weak) IBOutlet UIScrollView *sourceScrollView;

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
    
    self.sourceScrollView.backgroundColor = self.view.backgroundColor;
    self.sourceScrollView.clipsToBounds = NO;
    
    self.headerView.item = self.item;
    self.typeView.delegate = self;
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
    [self.headerView setNeedsTopConstraintsUpdateForStatusBarAppearence:self.headerView.hidden];
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
    
    [self.stackView layoutIfNeeded];
    [self setNeedsStatusBarAppearanceUpdate];
    [self.headerView setNeedsTopConstraintsUpdateForStatusBarAppearence:self.headerView.hidden];
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
    
    [self.sourceView setHeaderViewsHidden:NO];
    
    if(!self.typeView.hidden) {
        self.typeView.hidden = YES;
        self.typeView.alpha = 0.0;
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
        
        if(!self.typeView.hidden) {
            self.typeView.hidden = YES;
            self.typeView.alpha = 0.0;
        }
        
        if(self.sourceView.hidden) {
            self.sourceView.hidden = NO;
            self.sourceView.alpha = 1.0;
        }
        
    }else {
        
        if(self.headerView.hidden) {
            self.headerView.hidden = NO;
            self.headerView.alpha = 1.0;
            [self.headerView setNeedsDisplay];
        }
        
        if(self.typeView.hidden) {
            self.typeView.hidden = NO;
            self.typeView.alpha = 1.0;
        }
        
        if(self.sourceView.hidden) {
            self.sourceView.hidden = NO;
            self.sourceView.alpha = 1.0;
        }
    }
    
    [self.sourceView setHeaderViewsHidden:YES];
    
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

- (void)updateForShowingTypeSelectionCompact
{
    [UIView animateWithDuration:0.20 animations:^{
        
        if(self.typeView.hidden) {
            self.typeView.hidden = NO;
            self.typeView.alpha = 1.0;
        }
        
        if(!self.sourceView.hidden) {
            self.sourceView.hidden = YES;
            self.sourceView.alpha = 0.0;
        }
    }];
}

- (void)updateForHidingTypeSelection
{
    [UIView animateWithDuration:0.20 animations:^{

        if(!self.typeView.hidden) {
            if([self shouldDisplayForCompactWidth]) {
                [self.sourceView setHeaderViewsHidden:NO];
                self.typeView.hidden = YES;
                self.typeView.alpha = 0.0;
            }
        }
        
        if(self.sourceView.hidden) {
            self.sourceView.hidden = NO;
            self.sourceView.alpha = 1.0;
        }
    }];
}

#pragma mark - MenuItemTypeSelectionViewDelegate

- (void)itemTypeSelectionViewChanged:(MenuItemTypeSelectionView *)typeSelectionView type:(MenuItemType)itemType
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // delays the layout update and upcoming animation
        // also fixes a layout drawing glitch when label have their bounds zeroed out from stackViews
        // Jan-8-2016 - Brent C.
        self.sourceView.selectedItemType = itemType;
        [self updateForHidingTypeSelection];
    });
}

- (BOOL)itemTypeSelectionViewRequiresCompactLayout:(MenuItemTypeSelectionView *)typeSelectionView
{
    return ![self shouldDisplayForCompactWidth];
}

#pragma mark - MenuItemSourceViewDelegate

- (void)sourceViewSelectedSourceTypeButton:(MenuItemSourceView *)sourceView
{
    if([self shouldDisplayForCompactWidth]) {
        [self updateForShowingTypeSelectionCompact];
    }
}

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
