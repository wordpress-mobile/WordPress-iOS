#import "MenuItemSourceView.h"
#import "MenusDesign.h"

@interface MenuItemSourceView ()

@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet UIStackView *stackView;
@property (nonatomic, strong) NSMutableArray *resultViews;

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
        stackView.distribution = UIStackViewDistributionEqualSpacing;
        stackView.alignment = UIStackViewAlignmentFill;
        stackView.spacing = MenusDesignDefaultContentSpacing;

        UIEdgeInsets margins = UIEdgeInsetsZero;
        margins.bottom = MenusDesignDefaultContentSpacing;
        stackView.layoutMargins = margins;
        stackView.layoutMarginsRelativeArrangement = YES;
    }
    {
        MenuItemSourceSearchBar *searchBar = [[MenuItemSourceSearchBar alloc] init];
        searchBar.translatesAutoresizingMaskIntoConstraints = NO;
        searchBar.delegate = self;
        [self.stackView addArrangedSubview:searchBar];
        
        NSLayoutConstraint *heightConstraint = [searchBar.heightAnchor constraintEqualToConstant:44.0];
        heightConstraint.priority = UILayoutPriorityDefaultHigh;
        heightConstraint.active = YES;
        
        [searchBar setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
        
        _searchBar = searchBar;
    }
    
    [self reloadResults];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.scrollView.contentSize = self.stackView.frame.size;
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
