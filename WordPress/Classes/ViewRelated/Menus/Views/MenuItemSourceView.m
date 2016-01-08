#import "MenuItemSourceView.h"
#import "MenusDesign.h"
#import "MenuItemSourceHeaderView.h"

@interface MenuItemSourceView () <MenuItemSourceHeaderViewDelegate>

@property (nonatomic, strong) MenuItemSourceHeaderView *headerView;
@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet UIStackView *stackView;
@property (nonatomic, strong) UIView *spacerView;
@property (nonatomic, strong) NSMutableArray *resultViews;
@property (nonatomic, assign) BOOL setContentSize;

@end

@implementation MenuItemSourceView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.results = [NSMutableArray array];
    
    {
        MenuItemSourceResult *result = [MenuItemSourceResult new];
        result.title = @"Home";
        result.badgeTitle = @"Site";
        result.selected = YES;
        [self.results addObject:result];
    }
    {
        MenuItemSourceResult *result = [MenuItemSourceResult new];
        result.title = @"About";
        [self.results addObject:result];
    }
    {
        MenuItemSourceResult *result = [MenuItemSourceResult new];
        result.title = @"Work";
        [self.results addObject:result];
    }
    {
        MenuItemSourceResult *result = [MenuItemSourceResult new];
        result.title = @"Contact";
        [self.results addObject:result];
    }
    {
        MenuItemSourceResult *result = [MenuItemSourceResult new];
        result.title = @"About";
        [self.results addObject:result];
    }
    {
        MenuItemSourceResult *result = [MenuItemSourceResult new];
        result.title = @"Work";
        [self.results addObject:result];
    }
    {
        MenuItemSourceResult *result = [MenuItemSourceResult new];
        result.title = @"Contact";
        [self.results addObject:result];
    }
    
    self.backgroundColor = [UIColor whiteColor];
    self.translatesAutoresizingMaskIntoConstraints = NO;
    
    {
        UIStackView *stackView = self.stackView;
        stackView.translatesAutoresizingMaskIntoConstraints = NO;
        stackView.distribution = UIStackViewDistributionFill;
        stackView.alignment = UIStackViewAlignmentTop;
        stackView.spacing = 0;
    }
    {
        MenuItemSourceHeaderView *headerView = [[MenuItemSourceHeaderView alloc] init];
        headerView.delegate = self;
        [self.stackView addArrangedSubview:headerView];
        
        [headerView.widthAnchor constraintEqualToAnchor:self.widthAnchor].active = YES;
        
        self.headerView = headerView;
    }
    {
        UIView *spacer = [[UIView alloc] init];
        NSLayoutConstraint *heightConstraint = [spacer.heightAnchor constraintEqualToConstant:MenusDesignDefaultContentSpacing / 2.0];
        heightConstraint.priority = UILayoutPriorityDefaultHigh;
        heightConstraint.active = YES;
        
        [self.stackView addArrangedSubview:spacer];
        
        [spacer.widthAnchor constraintEqualToAnchor:self.widthAnchor].active = YES;
        
        self.spacerView = spacer;
    }
    {
        MenuItemSourceSearchBar *searchBar = [[MenuItemSourceSearchBar alloc] init];
        searchBar.translatesAutoresizingMaskIntoConstraints = NO;
        searchBar.delegate = self;
        [self.stackView addArrangedSubview:searchBar];
        
        [searchBar.widthAnchor constraintEqualToAnchor:self.widthAnchor].active = YES;
        
        NSLayoutConstraint *heightConstraint = [searchBar.heightAnchor constraintEqualToConstant:MenusDesignGeneralCellHeight];
        heightConstraint.priority = UILayoutPriorityDefaultHigh;
        heightConstraint.active = YES;
        
        [searchBar setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
        _searchBar = searchBar;
    }
    
    [self reloadResults];
}

- (void)setHeaderViewsHidden:(BOOL)hidden
{
    if(self.headerView.hidden != hidden) {
        self.headerView.hidden = hidden;
        self.headerView.alpha = hidden ? 0.0 : 1.0;
    }
}

- (void)reloadResults
{
    for(UIView *view in self.resultViews) {
        [self.stackView removeArrangedSubview:view];
        [view removeFromSuperview];
    }
    
    self.resultViews = [NSMutableArray arrayWithCapacity:self.results.count];
    for(MenuItemSourceResult *result in self.results) {
        
        MenuItemSourceResultView *view = [[MenuItemSourceResultView alloc] init];
        view.result = result;
        [view setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
        
        [self.stackView addArrangedSubview:view];
        [self.resultViews addObject:view];
    }
}

#pragma mark - MenuItemSourceHeaderViewDelegate

- (void)sourceHeaderViewSelected:(MenuItemSourceHeaderView *)headerView
{
    [self.delegate sourceViewSelectedSourceTypeButton:self];
}

#pragma mark - MenuItemSourceSearchBarDelegate

- (void)sourceSearchBarDidBeginSearching:(MenuItemSourceSearchBar *)searchBar
{
    [self.delegate sourceViewDidBeginTyping:self];
}

- (void)sourceSearchBar:(MenuItemSourceSearchBar *)searchBar didUpdateSearchWithText:(NSString *)text
{
    
}

- (void)sourceSearchBarDidEndSearching:(MenuItemSourceSearchBar *)searchBar
{
    [self.delegate sourceViewDidEndTyping:self];
}

@end
