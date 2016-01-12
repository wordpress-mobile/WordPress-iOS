#import "MenuItemEditingViewController.h"
#import "MenuItem.h"
#import "WPStyleGuide.h"
#import "MenuItemEditingHeaderView.h"
#import "MenuItemEditingFooterView.h"
#import "MenuItemSourceView.h"
#import "MenuItemTypeSelectionView.h"

static CGFloat const MenuItemEditingFooterViewDefaultHeight = 60.0;
static CGFloat const MenuItemEditingFooterViewCompactHeight = 46.0;

typedef NS_ENUM(NSUInteger) {
    MenuItemEditingViewControllerContentLayoutDisplaysTypeView = 1,
    MenuItemEditingViewControllerContentLayoutDisplaysSourceView,
    MenuItemEditingViewControllerContentLayoutDisplaysTypeAndSourceViews,
}MenuItemEditingViewControllerContentLayout;

@interface MenuItemEditingViewController () <MenuItemSourceViewDelegate, MenuItemEditingFooterViewDelegate, MenuItemTypeSelectionViewDelegate>

@property (nonatomic, strong) IBOutlet UIStackView *stackView;
@property (nonatomic, strong) IBOutlet UIView *contentView;

@property (nonatomic, strong) IBOutlet MenuItemEditingHeaderView *headerView;
@property (nonatomic, strong) IBOutlet MenuItemEditingFooterView *footerView;
@property (nonatomic, strong) IBOutlet MenuItemTypeSelectionView *typeView;
@property (nonatomic, strong) IBOutlet MenuItemSourceView *sourceView;
@property (nonatomic, weak) IBOutlet UIScrollView *sourceScrollView;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *stackViewBottomConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *footerViewHeightConstraint;

@property (nonatomic, assign) MenuItemEditingViewControllerContentLayout contentLayout;
@property (nonatomic, strong) NSArray *layoutConstraintsForDisplayingTypeView;
@property (nonatomic, strong) NSArray *layoutConstraintsForDisplayingSourceView;
@property (nonatomic, strong) NSArray *layoutConstraintsForDisplayingSourceAndTypeViews;

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
    
    [self loadContentLayoutConstraints];
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

- (void)loadContentLayoutConstraints
{
    {
        // synchronize the height of the sourceView's headerView to the height of the first item in the typeView stack
        // this is a design detail and serves no other purpose
        NSLayoutAnchor *anchor = [self.typeView firstArrangedSubViewInLayout].heightAnchor;
        [self.sourceView activateHeightConstraintForHeaderViewWithHeightAnchor:anchor];
    }
    {
        self.layoutConstraintsForDisplayingTypeView = @[
                                                        [self.typeView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
                                                        [self.typeView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
                                                        [self.sourceView.leadingAnchor constraintEqualToAnchor:self.typeView.trailingAnchor],
                                                        [self.sourceView.widthAnchor constraintEqualToAnchor:self.contentView.widthAnchor]
                                                        ];
    }
    {
        self.layoutConstraintsForDisplayingSourceView = @[
                                                          [self.typeView.trailingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
                                                          [self.typeView.widthAnchor constraintEqualToAnchor:self.contentView.widthAnchor],
                                                          [self.sourceView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
                                                          [self.sourceView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor]
                                                          ];
    }
    {
        self.layoutConstraintsForDisplayingSourceAndTypeViews = @[
                                                                  [self.typeView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
                                                                  [self.typeView.widthAnchor constraintEqualToConstant:180.0],
                                                                  [self.sourceView.leadingAnchor constraintEqualToAnchor:self.typeView.trailingAnchor],
                                                                  [self.sourceView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor]
                                                                  ];
    }
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
    
    if(self.sourceView.headerView.hidden) {
        self.sourceView.headerView.hidden = NO;
        self.sourceView.headerView.alpha = 1.0;
    }
    
    [self setContentLayout:MenuItemEditingViewControllerContentLayoutDisplaysSourceView];
    
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
        
        [self setContentLayout:MenuItemEditingViewControllerContentLayoutDisplaysSourceView];
        
    }else {
        
        if(self.headerView.hidden) {
            self.headerView.hidden = NO;
            self.headerView.alpha = 1.0;
            [self.headerView setNeedsDisplay];
        }
        
        [self setContentLayout:MenuItemEditingViewControllerContentLayoutDisplaysTypeAndSourceViews];
    }
    
    if(!self.sourceView.headerView.hidden) {
        self.sourceView.headerView.hidden = YES;
        self.sourceView.headerView.alpha = 0.0;
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

- (void)setContentLayout:(MenuItemEditingViewControllerContentLayout)contentLayout
{
    if(_contentLayout != contentLayout) {
        
        switch (_contentLayout) {
            case MenuItemEditingViewControllerContentLayoutDisplaysTypeView:
            {
                [NSLayoutConstraint deactivateConstraints:self.layoutConstraintsForDisplayingTypeView];
                break;
            }
            case MenuItemEditingViewControllerContentLayoutDisplaysSourceView:
            {
                [NSLayoutConstraint deactivateConstraints:self.layoutConstraintsForDisplayingSourceView];
                break;
            }
            case MenuItemEditingViewControllerContentLayoutDisplaysTypeAndSourceViews:
            {
                [NSLayoutConstraint deactivateConstraints:self.layoutConstraintsForDisplayingSourceAndTypeViews];
                break;
            }
        }
        
        _contentLayout = contentLayout;
        
        switch (contentLayout) {
            case MenuItemEditingViewControllerContentLayoutDisplaysTypeView:
            {
                [NSLayoutConstraint activateConstraints:self.layoutConstraintsForDisplayingTypeView];
                break;
            }
            case MenuItemEditingViewControllerContentLayoutDisplaysSourceView:
            {
                [NSLayoutConstraint activateConstraints:self.layoutConstraintsForDisplayingSourceView];
                break;
            }
            case MenuItemEditingViewControllerContentLayoutDisplaysTypeAndSourceViews:
            {
                [NSLayoutConstraint activateConstraints:self.layoutConstraintsForDisplayingSourceAndTypeViews];
                break;
            }
        }
    }
}

- (void)updateForShowingTypeSelectionCompact
{
    [self setContentLayout:MenuItemEditingViewControllerContentLayoutDisplaysTypeView];
    [UIView animateWithDuration:0.15 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        
        [self.contentView layoutIfNeeded];
        
    } completion:nil];
}

- (void)updateForHidingTypeSelection
{
    BOOL hideTypeView = NO;
    
    if([self shouldDisplayForCompactWidth]) {
        if(self.sourceView.headerView.hidden) {
            self.sourceView.headerView.hidden = NO;
            self.sourceView.headerView.alpha = 1.0;
        }
        hideTypeView = YES;
    }
    
    if(hideTypeView) {
        [self setContentLayout:MenuItemEditingViewControllerContentLayoutDisplaysSourceView];
    }else {
        [self setContentLayout:MenuItemEditingViewControllerContentLayoutDisplaysTypeAndSourceViews];
    }
    
    [UIView animateWithDuration:0.15 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        
        [self.contentView layoutIfNeeded];
        
    } completion:nil];
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
