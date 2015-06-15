#import "WPSearchControllerConfigurator.h"
#import "WordPress-Swift.h"

const CGFloat SearchBarWidth = 280.0;
const CGFloat SearchBariPadWidth = 600.0;
const CGFloat SearchWrapperViewPortraitHeight = 64.0;
const CGFloat SearchWrapperViewLandscapeHeight = 44.0;
const NSTimeInterval SearchBarAnimationDuration = 0.2; // seconds

@interface WPSearchControllerConfigurator ()

@property (nonatomic, weak) WPSearchController *searchController;
@property (nonatomic, weak) id<WPSearchControllerDelegate, WPSearchResultsUpdating> delegate;
@property (nonatomic, weak) UIView *searchWrapperView;
@property (nonatomic, weak) UISearchBar *searchBar;

@end

@implementation WPSearchControllerConfigurator

- (instancetype)initWithSearchController:(WPSearchController *)searchController
                   withSearchWrapperView:(UIView *)searchWrapperView
                             withDelegate:(id<WPSearchControllerDelegate, WPSearchResultsUpdating>)delegate
{
    self = [super init];
    if (self) {
        _searchController = searchController;
        _searchWrapperView = searchWrapperView;
        _delegate = delegate;
        _searchBar = _searchController.searchBar;
    }
    
    return self;
}

- (void)configureSearchControllerBarAndWrapperView
{
    [self configureSearchController];
    [self configureSearchBar];
    [self configureSearchWrapper];
}

- (void)configureSearchController
{
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.hidesNavigationBarDuringPresentation = YES;
    self.searchController.delegate = self.delegate;
    self.searchController.searchResultsUpdater = self.delegate;
}

- (void)configureSearchBar
{
    [self configureSearchBarPlaceholder];
    
    self.searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchBar.accessibilityIdentifier = @"Search";
    self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.searchBar.backgroundImage = [[UIImage alloc] init];
    self.searchBar.tintColor = [WPStyleGuide grey]; // cursor color
    self.searchBar.translucent = NO;
    [self.searchBar setImage:[UIImage imageNamed:@"icon-clear-textfield"] forSearchBarIcon:UISearchBarIconClear state:UIControlStateNormal];
    [self.searchBar setImage:[UIImage imageNamed:@"icon-post-list-search"] forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
    
    [self configureSearchBarForSearchView];
}

- (void)configureSearchBarPlaceholder
{
    // Adjust color depending on where the search bar is being presented.
    UIColor *placeholderColor = [WPStyleGuide wordPressBlue];
    NSString *placeholderText = NSLocalizedString(@"Search", @"Placeholder text for the search bar on the post screen.");
    NSAttributedString *attrPlacholderText = [[NSAttributedString alloc] initWithString:placeholderText attributes:[WPStyleGuide defaultSearchBarTextAttributes:placeholderColor]];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], [self.delegate class], nil] setAttributedPlaceholder:attrPlacholderText];
}

- (void)configureSearchBarForSearchView
{
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], [self.delegate class], nil] setDefaultTextAttributes:[WPStyleGuide defaultSearchBarTextAttributes:[UIColor whiteColor]]];
    
    UISearchBar *searchBar = self.searchController.searchBar;
    searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    searchBar.barStyle = UIBarStyleBlack;
    searchBar.barTintColor = [WPStyleGuide wordPressBlue];
    searchBar.showsCancelButton = YES;
    
    [self.searchWrapperView addSubview:searchBar];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(searchBar);
    NSDictionary *metrics = @{@"searchbarWidth":@(SearchBariPadWidth)};
    if ([UIDevice isPad]) {
        [self.searchWrapperView addConstraint:[NSLayoutConstraint constraintWithItem:searchBar
                                                                           attribute:NSLayoutAttributeCenterX
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self.searchWrapperView
                                                                           attribute:NSLayoutAttributeCenterX
                                                                          multiplier:1.0
                                                                            constant:0.0]];
        [self.searchWrapperView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[searchBar(searchbarWidth)]"
                                                                                       options:0
                                                                                       metrics:metrics
                                                                                         views:views]];
    } else {
        [self.searchWrapperView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[searchBar]|"
                                                                                       options:0
                                                                                       metrics:metrics
                                                                                         views:views]];
    }
    [self.searchWrapperView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[searchBar]|"
                                                                                   options:0
                                                                                   metrics:metrics
                                                                                     views:views]];
}

- (void)configureSearchWrapper
{
    self.searchWrapperView.backgroundColor = [WPStyleGuide wordPressBlue];
}

@end
