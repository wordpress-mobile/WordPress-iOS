#import "MenuItemEditingViewController.h"
#import "Menu.h"
#import "MenuItem.h"
#import "Blog.h"
#import "MenuItemEditingHeaderView.h"
#import "MenuItemEditingFooterView.h"
#import "MenuItemSourceViewController.h"
#import "MenuItemTypeViewController.h"
#import "ContextManager.h"
#import <WordPressShared/WPDeviceIdentification.h>
#import <WordPressShared/WPStyleGuide.h>
#import "WordPress-Swift.h"

NSString * const MenuItemEditingTypeSelectionChangedNotification = @"MenuItemEditingTypeSelectionChangedNotification";

static CGFloat const FooterViewDefaultHeight = 49.0;
static CGFloat const FooterViewCompactHeight = 44.0;
static CGFloat const TypeViewCompactWidth = 180.0;
static CGFloat const TypeViewSelectionBurnDelay = 0.10;
static CGFloat const LayoutTransitionDuration = 0.15;

typedef NS_ENUM(NSUInteger, MenuItemEditingViewControllerContentLayout) {
    MenuItemEditingViewControllerContentLayoutDisplaysTypeView = 1,
    MenuItemEditingViewControllerContentLayoutDisplaysSourceView,
    MenuItemEditingViewControllerContentLayoutDisplaysTypeAndSourceViews,
};

@interface MenuItemEditingViewController () <MenuItemSourceViewControllerDelegate, MenuItemEditingHeaderViewDelegate, MenuItemEditingFooterViewDelegate, MenuItemTypeViewControllerDelegate>

@property (nonatomic, strong, readonly) MenuItem *item;
@property (nonatomic, strong, readonly) Blog *blog;

@property (nonatomic, strong, readonly) NSManagedObjectContext *scratchObjectContext;

@property (nonatomic, strong) IBOutlet UIStackView *stackView;
@property (nonatomic, strong) IBOutlet UIView *contentView;

@property (nonatomic, strong) IBOutlet MenuItemEditingHeaderView *headerView;
@property (nonatomic, strong) IBOutlet MenuItemEditingFooterView *footerView;

@property (nonatomic, weak) MenuItemTypeViewController *typeViewController;
@property (nonatomic, weak) MenuItemSourceViewController *sourceViewController;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *stackViewBottomConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *footerViewHeightConstraint;

@property (nonatomic, assign) MenuItemEditingViewControllerContentLayout contentLayout;
@property (nonatomic, strong) NSArray *layoutConstraintsForDisplayingTypeView;
@property (nonatomic, strong) NSArray *layoutConstraintsForDisplayingSourceView;
@property (nonatomic, strong) NSArray *layoutConstraintsForDisplayingSourceAndTypeViews;

@property (nonatomic, assign) BOOL sourceViewIsTyping;

@end

@implementation MenuItemEditingViewController

+ (MenuItemEditingViewController *)itemEditingViewControllerWithItem:(MenuItem *)item blog:(Blog *)blog
{
    NSParameterAssert([blog isKindOfClass:[Blog class]]);
    NSParameterAssert([item isKindOfClass:[MenuItem class]]);
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MenuItemEditing" bundle:nil];
    MenuItemEditingViewController *controller = [storyboard instantiateInitialViewController];
    [controller setupWithItem:item blog:blog];
    return controller;
}

- (void)setupWithItem:(MenuItem *)item blog:(Blog *)blog
{
    _blog = blog;

    // Keep track of changes to the item on a scratch contect and scratch item.
    NSManagedObjectID *itemObjectID = item.objectID;
    NSManagedObjectContext *scratchContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    scratchContext.parentContext = blog.managedObjectContext;
    scratchContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
    _scratchObjectContext = scratchContext;

    [scratchContext performBlockAndWait:^{
        NSError *error;
        MenuItem *itemInContext = [scratchContext existingObjectWithID:itemObjectID error:&error];
        if (error) {
            DDLogError(@"Error occurred obtaining existing MenuItem object in context: %@", error);
        }
        self->_item = itemInContext;
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor murielListForeground];

    self.headerView.item = self.item;

    self.headerView.delegate = self;
    self.typeViewController.delegate = self;
    self.sourceViewController.delegate = self;
    self.footerView.delegate = self;

    [self.stackView bringSubviewToFront:self.headerView];

    [self loadContentLayoutConstraints];
    [self updateLayoutIfNeeded];

    self.typeViewController.selectedItemType = self.item.type;
    [self.typeViewController loadPostTypesForBlog:self.blog];

    self.sourceViewController.blog = self.blog;
    self.sourceViewController.item = self.item;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHideNotification:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowNotification:) name:UIKeyboardWillShowNotification object:nil];
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [super prepareForSegue:segue sender:sender];

    if ([segue.destinationViewController isKindOfClass:[MenuItemSourceViewController class]]) {
        self.sourceViewController = segue.destinationViewController;
    } else if ([segue.destinationViewController isKindOfClass:[MenuItemTypeViewController class]]) {
        self.typeViewController = segue.destinationViewController;
    }
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
    self.layoutConstraintsForDisplayingTypeView = @[
                                                    [self.typeViewController.view.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
                                                    [self.typeViewController.view.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
                                                    [self.sourceViewController.view.leadingAnchor constraintEqualToAnchor:self.typeViewController.view.trailingAnchor],
                                                    [self.sourceViewController.view.widthAnchor constraintEqualToAnchor:self.contentView.widthAnchor]
                                                    ];
    self.layoutConstraintsForDisplayingSourceView = @[
                                                      [self.typeViewController.view.trailingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
                                                      [self.typeViewController.view.widthAnchor constraintEqualToAnchor:self.contentView.widthAnchor],
                                                      [self.sourceViewController.view.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
                                                      [self.sourceViewController.view.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor]
                                                      ];
    self.layoutConstraintsForDisplayingSourceAndTypeViews = @[
                                                              [self.typeViewController.view.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
                                                              [self.typeViewController.view.widthAnchor constraintEqualToConstant:TypeViewCompactWidth],
                                                              [self.sourceViewController.view.leadingAnchor constraintEqualToAnchor:self.typeViewController.view.trailingAnchor],
                                                              [self.sourceViewController.view.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor]
                                                              ];
}

- (BOOL)shouldLayoutForCompactWidth
{
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
    BOOL minimizeLayoutForSourceViewTypying = compactWidthLayout && self.sourceViewIsTyping;

    if (minimizeLayoutForSourceViewTypying) {
        // headerView should be hidden while typing within the sourceView, to save screen space (iPhone)
        [self setHeaderViewHidden:YES];
    } else  {
        [self setHeaderViewHidden:NO];
    }

    if (!compactWidthLayout) {
        // on iPhone landscape we want to minimize the height of the footer to gain any vertical screen space we can
        self.footerViewHeightConstraint.constant = FooterViewCompactHeight;
    } else  {
        // restore the height of the footer on portrait since we have more vertical screen space
        self.footerViewHeightConstraint.constant = FooterViewDefaultHeight;
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
    [UIView animateWithDuration:LayoutTransitionDuration animations:^{
        [self updateLayoutIfNeeded];
    }];
}

- (void)transitionLayoutToDisplayTypeView
{
    [self setContentLayout:MenuItemEditingViewControllerContentLayoutDisplaysTypeView];
    [UIView animateWithDuration:LayoutTransitionDuration delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{

        [self.typeViewController updateDesignForLayoutChangeIfNeeded];
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
    [UIView animateWithDuration:LayoutTransitionDuration delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{

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

        if (contentLayout == MenuItemEditingViewControllerContentLayoutDisplaysTypeAndSourceViews) {
            [self.sourceViewController setHeaderViewHidden:YES];
        } else {
            [self.sourceViewController setHeaderViewHidden:NO];
        }
    }
}

#pragma mark - MenuItemTypeViewControllerDelegate

- (void)itemTypeViewController:(MenuItemTypeViewController *)itemTypeViewController selectedType:(NSString *)itemType
{
    [self.sourceViewController updateSourceSelectionForItemType:itemType];
    self.headerView.itemType = itemType;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(TypeViewSelectionBurnDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self transitionLayoutToDisplaySourceView];
    });
}

- (BOOL)itemTypeViewControllerShouldDisplayFullSizedLayout:(MenuItemTypeViewController *)itemTypeViewController
{
    return self.contentLayout == MenuItemEditingViewControllerContentLayoutDisplaysTypeView;
}

#pragma mark - MenuItemSourceViewControllerDelegate

- (void)sourceResultsViewControllerDidUpdateItem:(MenuItemSourceViewController *)sourceViewController
{
    self.headerView.item = sourceViewController.item;
}

- (void)sourceViewControllerTypeHeaderViewWasPressed:(MenuItemSourceViewController *)sourceViewController
{
    if ([self shouldLayoutForCompactWidth]) {
        [self transitionLayoutToDisplayTypeView];
    }
}

- (void)sourceViewControllerDidBeginEditingWithKeyboard:(MenuItemSourceViewController *)sourceViewController
{
    self.sourceViewIsTyping = YES;
    [self updateLayoutIfNeededAnimated];
}

- (void)sourceViewControllerDidEndEditingWithKeyboard:(MenuItemSourceViewController *)sourceViewController
{
    self.sourceViewIsTyping = NO;
    [self updateLayoutIfNeededAnimated];
}

#pragma mark - MenuItemEditingHeaderViewDelegate

- (void)editingHeaderView:(MenuItemEditingHeaderView *)headerView didUpdateTextForItemName:(NSString *)text
{
    self.item.name = text.length ? text : nil;
    [self.sourceViewController refreshForUpdatedItemName];
}

#pragma mark - MenuItemEditingFooterViewDelegate

- (void)editingFooterViewDidSelectSave:(MenuItemEditingFooterView *)footerView
{
    // Update the original item in the correct context with any changes made in the scratch context/item.
    NSDictionary *changesValues = [self.item changedValues];
    if (changesValues.count > 0) {
        MenuItem *itemInMainContext = [self.blog.managedObjectContext objectRegisteredForID:self.item.objectID];
        [itemInMainContext setValuesForKeysWithDictionary:changesValues];
    }
    if (self.onSelectedToSave) {
        self.onSelectedToSave();
    }
}

- (void)editingFooterViewDidSelectTrash:(MenuItemEditingFooterView *)footerView
{
    if (self.onSelectedToTrash) {
        self.onSelectedToTrash();
    }
}

- (void)editingFooterViewDidSelectCancel:(MenuItemEditingFooterView *)footerView
{
    if (self.onSelectedToCancel) {
        self.onSelectedToCancel();
    }
}

#pragma mark - notifications

- (void)updateWithKeyboardNotification:(NSNotification *)notification
{
    CGRect frame = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    frame = [self.view.window convertRect:frame toView:self.view];

    CGFloat constraintConstant;
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
    self.stackViewBottomConstraint.constant = 0;
    [self.view layoutIfNeeded];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)keyboardWillShowNotification:(NSNotification *)notification
{
    [self updateWithKeyboardNotification:notification];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrameNotification:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)keyboardWillChangeFrameNotification:(NSNotification *)notification
{
    [self updateWithKeyboardNotification:notification];
}

@end
