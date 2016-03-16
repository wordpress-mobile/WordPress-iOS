#import "MenuItemEditingViewController.h"
#import "Menu.h"
#import "MenuItem.h"
#import "Blog.h"
#import "WPStyleGuide.h"
#import "MenuItemEditingHeaderView.h"
#import "MenuItemEditingFooterView.h"
#import "MenuItemSourceContainerView.h"
#import "MenuItemTypeSelectionView.h"
#import "ContextManager.h"

NSString * const MenuItemEditingTypeSelectionChangedNotification = @"MenuItemEditingTypeSelectionChangedNotification";

static CGFloat const MenuItemEditingFooterViewDefaultHeight = 60.0;
static CGFloat const MenuItemEditingFooterViewCompactHeight = 46.0;

typedef NS_ENUM(NSUInteger) {
    MenuItemEditingViewControllerContentLayoutDisplaysTypeView = 1,
    MenuItemEditingViewControllerContentLayoutDisplaysSourceView,
    MenuItemEditingViewControllerContentLayoutDisplaysTypeAndSourceViews,
}MenuItemEditingViewControllerContentLayout;

@interface MenuItemEditingViewController () <MenuItemSourceContainerViewDelegate, MenuItemEditingFooterViewDelegate, MenuItemTypeSelectionViewDelegate>

@property (nonatomic, strong) MenuItem *item;
@property (nonatomic, strong) Blog *blog;

/**
 The "scratch pad" child context for changes on the item to save, or discard.
 */
@property (nonatomic, strong) NSManagedObjectContext *scratchObjectContext;

@property (nonatomic, strong) IBOutlet UIStackView *stackView;
@property (nonatomic, strong) IBOutlet UIView *contentView;

@property (nonatomic, strong) IBOutlet MenuItemEditingHeaderView *headerView;
@property (nonatomic, strong) IBOutlet MenuItemEditingFooterView *footerView;
@property (nonatomic, strong) IBOutlet MenuItemTypeSelectionView *typeView;
@property (nonatomic, strong) IBOutlet MenuItemSourceContainerView *sourceView;
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

- (id)initWithItem:(MenuItem *)item blog:(Blog *)blog
{
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];
    if (self) {
        
        self.blog = blog;
        
        NSManagedObjectID *itemObjectID = item.objectID;
        NSManagedObjectContext *scratchContext = [[ContextManager sharedInstance] newMainContextChildContext];
        self.scratchObjectContext = scratchContext;
        
        [scratchContext performBlockAndWait:^{
            MenuItem *itemInContext = [scratchContext objectWithID:itemObjectID];
            self.item = itemInContext;
        }];
    }
    
    return self;
}

- (void)loadView
{
    [super loadView];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.sourceScrollView.backgroundColor = self.view.backgroundColor;
    self.sourceScrollView.clipsToBounds = NO;
    
    self.headerView.item = self.item;
    
    self.typeView.delegate = self;
    self.sourceView.delegate = self;
    self.footerView.delegate = self;
    
    [self.stackView bringSubviewToFront:self.headerView];
    
    [self loadContentLayoutConstraints];
    [self updateLayoutIfNeeded];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.typeView.selectedItemType = self.item.type;
    [self.typeView loadPostTypesForBlog:self.item.menu.blog];
    
    self.sourceView.blog = self.blog;
    self.sourceView.item = self.item;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.modalPresentationStyle == UIModalPresentationFormSheet) {
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
    [self updateLayoutIfNeeded];
}

- (void)loadContentLayoutConstraints
{
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

- (BOOL)shouldLayoutForCompactWidth
{
    if (IS_IPAD) {
        return NO;
    }
    
    BOOL horizontallyCompact = [self.traitCollection containsTraitsInCollection:[UITraitCollection traitCollectionWithHorizontalSizeClass:UIUserInterfaceSizeClassCompact]];
    
    if (horizontallyCompact) {
        
        if ([self.traitCollection containsTraitsInCollection:[UITraitCollection traitCollectionWithVerticalSizeClass:UIUserInterfaceSizeClassCompact]]) {
            horizontallyCompact = NO;
        }
    }
    
    return horizontallyCompact;
}

#pragma mark - layout changes

- (void)setHeaderViewHidden:(BOOL)hidden
{
    if (self.headerView.hidden != hidden) {
        self.headerView.hidden = hidden;
        self.headerView.alpha = hidden ? 0.0 : 1.0;
        if (!hidden) {
            [self.headerView setNeedsDisplay];
        }
    }
}

- (void)updateLayoutIfNeeded
{
    // compactWidthLayout is any screen size in which the width is less than the height (iPhone portrait)
    BOOL compactWidthLayout = [self shouldLayoutForCompactWidth];
    BOOL minimizeLayoutForSourceViewTypying = !IS_IPAD && self.sourceViewIsTyping;
    
    if (minimizeLayoutForSourceViewTypying) {
        // headerView should be hidden while typing within the sourceView, to save screen space (iPhone)
        [self setHeaderViewHidden:YES];
    } else  {
        [self setHeaderViewHidden:NO];
    }
    
    if (!IS_IPAD) {
        
        if (!compactWidthLayout) {
            // on iPhone landscape we want to minimize the height of the footer to gain any vertical screen space we can
            self.footerViewHeightConstraint.constant = MenuItemEditingFooterViewCompactHeight;
        } else  {
            // restore the height of the footer on portrait since we have more vertical screen space
            self.footerViewHeightConstraint.constant = MenuItemEditingFooterViewDefaultHeight;
        }
    }
    
    if (compactWidthLayout || minimizeLayoutForSourceViewTypying) {
        
        [self setContentLayout:MenuItemEditingViewControllerContentLayoutDisplaysSourceView];
        
    } else  {
        
        [self setContentLayout:MenuItemEditingViewControllerContentLayoutDisplaysTypeAndSourceViews];
    }

    [self.stackView layoutIfNeeded];
    [self setNeedsStatusBarAppearanceUpdate];
    [self.headerView setNeedsTopConstraintsUpdateForStatusBarAppearence:self.headerView.hidden];
}

- (void)updateLayoutIfNeededAnimated
{
    [self.stackView layoutIfNeeded];
    [UIView animateWithDuration:0.20 animations:^{
        [self updateLayoutIfNeeded];
    }];
}

- (void)transitionLayoutToDisplayTypeView
{
    [self setContentLayout:MenuItemEditingViewControllerContentLayoutDisplaysTypeView];
    [UIView animateWithDuration:0.15 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        
        [self.typeView updateDesignForLayoutChangeIfNeeded];
        [self.contentView layoutIfNeeded];
        
    } completion:nil];
}

- (void)transitionLayoutToDisplaySourceView
{
    if ([self shouldLayoutForCompactWidth]) {
        [self setContentLayout:MenuItemEditingViewControllerContentLayoutDisplaysSourceView];
    } else  {
        [self setContentLayout:MenuItemEditingViewControllerContentLayoutDisplaysTypeAndSourceViews];
    }
    
    [UIView animateWithDuration:0.15 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        
        [self.contentView layoutIfNeeded];
        
    } completion:nil];
}

- (void)setContentLayout:(MenuItemEditingViewControllerContentLayout)contentLayout
{
    if (_contentLayout != contentLayout) {
        
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

#pragma mark - MenuItemTypeSelectionViewDelegate

- (void)itemTypeSelectionViewChanged:(MenuItemTypeSelectionView *)typeSelectionView type:(NSString *)itemType
{
    [self.sourceView updateSourceSelectionForItemType:itemType];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self transitionLayoutToDisplaySourceView];
    });
}

- (BOOL)itemTypeSelectionViewRequiresFullSizedLayout:(MenuItemTypeSelectionView *)typeSelectionView
{
    return self.contentLayout == MenuItemEditingViewControllerContentLayoutDisplaysTypeView;
}

#pragma mark - MenuItemSourceContainerViewDelegate

- (void)sourceContainerViewSelectedTypeHeaderView:(MenuItemSourceContainerView *)sourceView
{
    if ([self shouldLayoutForCompactWidth]) {
        [self transitionLayoutToDisplayTypeView];
    }
}

- (void)sourceContainerViewDidBeginEditingWithKeyboard:(MenuItemSourceContainerView *)sourceView
{
    self.sourceViewIsTyping = YES;
    [self updateLayoutIfNeededAnimated];
}

- (void)sourceContainerViewDidEndEditingWithKeyboard:(MenuItemSourceContainerView *)sourceView
{
    self.sourceViewIsTyping = NO;
    [self updateLayoutIfNeededAnimated];
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
    
    if (frame.origin.y > self.view.frame.size.height) {
        constraintConstant = 0.0;
    } else  {
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
    if (self.observesKeyboardChanges) {
        [self updateWithKeyboardNotification:notification];
    }
}

@end
