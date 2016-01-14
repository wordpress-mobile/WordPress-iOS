#import "MenuItemSourceContainerView.h"
#import "MenusDesign.h"
#import "MenuItemSourceHeaderView.h"
#import "MenuItemSourcePageView.h"
#import "MenuItemSourceLinkView.h"
#import "MenuItemSourceCategoryView.h"
#import "MenuItemSourceTagView.h"
#import "MenuItemSourcePostView.h"

@interface MenuItemSourceContainerView () <MenuItemSourceHeaderViewDelegate, MenuItemSourceViewDelegate>

@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet UIStackView *stackView;
@property (nonatomic, strong) MenuItemSourceHeaderView *headerView;
@property (nonatomic, strong) MenuItemSourceView *sourceView;
@property (nonatomic, strong) NSCache *sourceViewCache;

@end

@implementation MenuItemSourceContainerView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = [UIColor whiteColor];
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.sourceViewCache = [[NSCache alloc] init];
    
    {
        UIStackView *stackView = self.stackView;
        stackView.translatesAutoresizingMaskIntoConstraints = NO;
        stackView.distribution = UIStackViewDistributionFill;
        stackView.alignment = UIStackViewAlignmentFill;
        stackView.spacing = 0;
    }
    {
        MenuItemSourceHeaderView *headerView = [[MenuItemSourceHeaderView alloc] init];
        headerView.delegate = self;
        headerView.itemType = MenuItemTypePage;
        [self.stackView addArrangedSubview:headerView];
        
        NSLayoutConstraint *height = [headerView.heightAnchor constraintEqualToConstant:60.0];
        height.priority = 999;
        height.active = YES;
        
        [headerView setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
        
        self.headerView = headerView;
    }
    
    self.selectedItemType = MenuItemTypePage;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    if(self.frame.size.width > self.frame.size.height) {
        [self setHeaderViewHidden:YES];
    }else {
        [self setHeaderViewHidden:NO];
    }
}

- (void)setHeaderViewHidden:(BOOL)hidden
{
    if(self.headerView.hidden != hidden) {
        self.headerView.hidden = hidden;
        self.headerView.alpha = hidden ? 0.0 : 1.0;
    }
}

- (void)setItem:(MenuItem *)item
{
    if(_item != item) {
        _item = item;
        self.sourceView.item = item;
    }
}

- (void)setSelectedItemType:(MenuItemType)selectedItemType
{
    if(_selectedItemType != selectedItemType) {
        _selectedItemType = selectedItemType;
        self.headerView.itemType = selectedItemType;
        [self showSourceViewForItemType:selectedItemType];
    }
}

- (void)showSourceViewForItemType:(MenuItemType)itemType
{
    if(self.sourceView) {
        [self.stackView removeArrangedSubview:self.sourceView];
        [self.sourceView removeFromSuperview];
        self.sourceView = nil;
    }
    
    MenuItemSourceView *sourceView = nil;
    NSString *cacheIdentifier = [self cacheIdentifierForSourceViewWithItemType:itemType];
    if(cacheIdentifier) {
        sourceView = [self.sourceViewCache objectForKey:cacheIdentifier];
    }
    if(!sourceView) {
        switch (itemType) {
            case MenuItemTypePage:
                sourceView = [[MenuItemSourcePageView alloc] init];
                break;
            case MenuItemTypeLink:
                sourceView = [[MenuItemSourceLinkView alloc] init];
                break;
            case MenuItemTypeCategory:
                sourceView = [[MenuItemSourceCategoryView alloc] init];
                break;
            case MenuItemTypeTag:
                sourceView = [[MenuItemSourceTagView alloc] init];
                break;
            case MenuItemTypePost:
                sourceView = [[MenuItemSourcePostView alloc] init];
                break;
            case MenuItemTypeCustom:
            case MenuItemTypeUnknown:
                // TODO: support misc item sources
                // Jan-12-2015 - Brent C.
                break;
        }
        
        sourceView.item = self.item;
        sourceView.delegate = self;
    }
    
    if(sourceView) {
        
        [self.stackView addArrangedSubview:sourceView];
        self.sourceView = sourceView;
        
        if(cacheIdentifier) {
            [self.sourceViewCache setObject:sourceView forKey:cacheIdentifier];
        }
    }
}

- (NSString *)cacheIdentifierForSourceViewWithItemType:(MenuItemType)itemType
{
    NSString *identifier = nil;
    
    switch (itemType) {
        case MenuItemTypePage:
            identifier = NSStringFromClass([MenuItemSourcePageView class]);
            break;
        case MenuItemTypeLink:
            identifier = NSStringFromClass([MenuItemSourceLinkView class]);
            break;
        case MenuItemTypeCategory:
            identifier = NSStringFromClass([MenuItemSourceCategoryView class]);
            break;
        case MenuItemTypeTag:
            identifier = NSStringFromClass([MenuItemSourceTagView class]);
            break;
        case MenuItemTypePost:
            identifier = NSStringFromClass([MenuItemSourcePostView class]);
            break;
        case MenuItemTypeCustom:
        case MenuItemTypeUnknown:
            // TODO: support misc item sources
            // Jan-12-2015 - Brent C.
            break;
    }
    
    return identifier;
}

#pragma mark - MenuItemSourceHeaderViewDelegate

- (void)sourceHeaderViewSelected:(MenuItemSourceHeaderView *)headerView
{
    [self.sourceView resignFirstResponder];
    [self.delegate sourceContainerViewSelectedTypeHeaderView:self];
}

#pragma mark - MenuItemSourceViewDelegate

- (void)sourceViewDidBeginEditingWithKeyBoard:(MenuItemSourceView *)sourceView
{
    [self.delegate sourceContainerViewDidBeginEditingWithKeyboard:self];
}

- (void)sourceViewDidEndEditingWithKeyboard:(MenuItemSourceView *)sourceView
{
    [self.delegate sourceContainerViewDidEndEditingWithKeyboard:self];
}

@end
