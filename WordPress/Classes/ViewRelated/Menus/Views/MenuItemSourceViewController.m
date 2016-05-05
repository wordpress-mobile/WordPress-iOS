#import "MenuItemSourceViewController.h"
#import "MenuItemSourceHeaderView.h"
#import "MenuItemSourcePageView.h"
#import "MenuItemSourceLinkView.h"
#import "MenuItemSourceCategoryView.h"
#import "MenuItemSourceTagView.h"
#import "MenuItemSourcePostView.h"
#import "Menu.h"

@interface MenuItemSourceViewController () <MenuItemSourceHeaderViewDelegate, MenuItemSourceViewDelegate>

@property (nonatomic, strong, readonly) UIStackView *stackView;
@property (nonatomic, strong, readonly) MenuItemSourceHeaderView *headerView;
@property (nonatomic, strong) MenuItemSourceView *sourceView;
@property (nonatomic, strong, readonly) NSCache *sourceViewCache;
@property (nonatomic, assign) BOOL itemNameWasUpdatedExternally;

@end

@implementation MenuItemSourceViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    _sourceViewCache = [[NSCache alloc] init];
    
    [self setupStackView];
    [self setupHeaderView];
}

- (void)setupStackView
{
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.distribution = UIStackViewDistributionFill;
    stackView.alignment = UIStackViewAlignmentFill;
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.spacing = 0;
    [self.view addSubview:stackView];
    
    [NSLayoutConstraint activateConstraints:@[
                                              [stackView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
                                              [stackView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
                                              [stackView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
                                              [stackView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
                                              [stackView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor]
                                              ]];
    
    _stackView = stackView;
}

- (void)setupHeaderView
{
    MenuItemSourceHeaderView *headerView = [[MenuItemSourceHeaderView alloc] init];
    headerView.delegate = self;
    
    NSAssert(_stackView != nil, @"stackView is nil");
    [_stackView addArrangedSubview:headerView];
    
    NSLayoutConstraint *height = [headerView.heightAnchor constraintEqualToConstant:60.0];
    height.priority = 999;
    height.active = YES;
    
    [headerView setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
    [headerView setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
    
    _headerView = headerView;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (IS_IPAD || self.view.frame.size.width > self.view.frame.size.height) {
        [self setHeaderViewHidden:YES];
    } else  {
        [self setHeaderViewHidden:NO];
    }
}

- (void)setHeaderViewHidden:(BOOL)hidden
{
    if (self.headerView.hidden != hidden) {
        self.headerView.hidden = hidden;
        self.headerView.alpha = hidden ? 0.0 : 1.0;
    }
}

- (void)setItem:(MenuItem *)item
{
    if (_item != item) {
        _item = item;
        [self updateSourceSelectionForItemType:item.type];
    }
}

- (void)updateSourceSelectionForItemType:(NSString *)itemType
{
    self.headerView.titleLabel.text = [MenuItem labelForType:itemType blog:[self blog]];
    [self showSourceViewForItemType:itemType];
}

- (void)refreshForUpdatedItemName
{
    self.itemNameWasUpdatedExternally = YES;
}

- (void)showSourceViewForItemType:(NSString *)itemType
{
    MenuItemSourceView *sourceView = [self.sourceViewCache objectForKey:itemType];
    if (self.sourceView) {
        if (self.sourceView == sourceView) {
            // No update needed.
            return;
        }
        [self.stackView removeArrangedSubview:self.sourceView];
        [self.sourceView removeFromSuperview];
        self.sourceView = nil;
    }
    
    BOOL sourceViewSetupRequired = NO;
    if (!sourceView) {
        if ([itemType isEqualToString:MenuItemTypePage]) {
            sourceView = [[MenuItemSourcePageView alloc] init];
        } else if ([itemType isEqualToString:MenuItemTypeCustom]) {
            sourceView = [[MenuItemSourceLinkView alloc] init];
        } else if ([itemType isEqualToString:MenuItemTypeCategory]) {
            sourceView = [[MenuItemSourceCategoryView alloc] init];
        } else if ([itemType isEqualToString:MenuItemTypeTag]) {
            sourceView = [[MenuItemSourceTagView alloc] init];
        } else {
            // Default to a post view that will load posts of postType == itemType.
            MenuItemSourcePostView *postView = [[MenuItemSourcePostView alloc] init];
            postView.postType = itemType;
            sourceView = postView;
        }
        sourceView.delegate = self;
        [sourceView setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
        [self.sourceViewCache setObject:sourceView forKey:itemType];
        sourceViewSetupRequired = YES;
    }
    
    [self.stackView addArrangedSubview:sourceView];
    self.sourceView = sourceView;
    
    if (sourceViewSetupRequired) {
        // Set the blog and item after it's been added as an arrangedSubview.
        sourceView.blog = self.blog;
        sourceView.item = self.item;
    } else {
        [sourceView refresh];
    }
}

#pragma mark - MenuItemSourceHeaderViewDelegate

- (void)sourceHeaderViewSelected:(MenuItemSourceHeaderView *)headerView
{
    [self.sourceView resignFirstResponder];
    [self.delegate sourceViewControllerPressedTypeHeaderView:self];
}

#pragma mark - MenuItemSourceViewDelegate

- (BOOL)sourceViewItemNameCanBeOverridden:(MenuItemSourceView *)sourceView
{
    // If the name is already empty or is using the default text, it can be overridden.
    if ([self.item nameIsEmptyOrDefault]) {
        if (self.itemNameWasUpdatedExternally) {
            /*
             If the item was previously updated externally, it's empty now.
             It can overridden again unless updated again externally. (see method: refreshForUpdatedItemName)
             */
            self.itemNameWasUpdatedExternally = NO;
        }
        return YES;
    }
    // If the name was not updated externally, such as the MenuItemEditingHeaderView, it can be overridden.
    if (!self.itemNameWasUpdatedExternally) {
        return YES;
    }
    return NO;
}

- (void)sourceViewDidUpdateItem:(MenuItemSourceView *)sourceView
{
    [self.delegate sourceViewControllerDidUpdateItem:self];
}

- (void)sourceViewDidBeginEditingWithKeyBoard:(MenuItemSourceView *)sourceView
{
    [self.delegate sourceViewControllerDidBeginEditingWithKeyboard:self];
}

- (void)sourceViewDidEndEditingWithKeyboard:(MenuItemSourceView *)sourceView
{
    [self.delegate sourceViewControllerDidEndEditingWithKeyboard:self];
}

@end
