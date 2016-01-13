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

@end

@implementation MenuItemSourceContainerView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = [UIColor whiteColor];
    self.translatesAutoresizingMaskIntoConstraints = NO;
    
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
    
    if(sourceView) {
    
        sourceView.item = self.item;
        sourceView.delegate = self;
        
        [self.stackView addArrangedSubview:sourceView];
        self.sourceView = sourceView;
    }
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
