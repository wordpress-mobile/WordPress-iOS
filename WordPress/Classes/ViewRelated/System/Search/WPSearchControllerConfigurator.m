#import "WPSearchControllerConfigurator.h"
#import "WordPress-Swift.h"

const CGFloat SearchBarWidth = 280.0;
const CGFloat SearchBariPadWidth = 600.0;
const CGFloat SearchWrapperViewPortraitHeight = 64.0;
const CGFloat SearchWrapperViewLandscapeHeight = 44.0;
const NSTimeInterval SearchBarAnimationDuration = 0.2; // seconds

@interface WPSearchControllerConfigurator ()

@property (nonatomic, weak) WPSearchController *searchController;
@property (nonatomic, weak) UIView *searchWrapperView;
@property (nonatomic, weak) UISearchBar *searchBar;

@end

@implementation WPSearchControllerConfigurator

- (instancetype)initWithSearchController:(WPSearchController *)searchController
                   withSearchWrapperView:(UIView *)searchWrapperView
{
    self = [super init];
    if (self) {
        _searchController = searchController;
        _searchWrapperView = searchWrapperView;
        _searchBar = _searchController.searchBar;
    }
    
    return self;
}

- (void)configureSearchControllerBarAndWrapperViewOfClass:(Class)class
{
    [self configureSearchController];
    [self configureSearchBar:class];
    [self configureSearchWrapper];
}

- (void)configureSearchController
{
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.hidesNavigationBarDuringPresentation = YES;
}

- (void)configureSearchBar:(Class)class
{
    [self configureSearchBarPlaceholder:class];
    
    self.searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchBar.accessibilityIdentifier = @"Search";
    self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.searchBar.backgroundImage = [[UIImage alloc] init];
    self.searchBar.tintColor = [WPStyleGuide grey]; // cursor color
    self.searchBar.translucent = NO;
    self.searchBar.barStyle = UIBarStyleBlack;
    self.searchBar.barTintColor = [WPStyleGuide wordPressBlue];
    self.searchBar.showsCancelButton = YES;
    [self.searchBar setImage:[UIImage imageNamed:@"icon-clear-textfield"] forSearchBarIcon:UISearchBarIconClear state:UIControlStateNormal];
    [self.searchBar setImage:[UIImage imageNamed:@"icon-post-list-search"] forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
    
    [self configureSearchBarForSearchView:class];
}

- (void)configureSearchBarPlaceholder:(Class)class
{
    // Adjust color depending on where the search bar is being presented.
    UIColor *placeholderColor = [WPStyleGuide wordPressBlue];
    NSString *placeholderText = NSLocalizedString(@"Search", @"Placeholder text for the search bar on the post screen.");
    NSAttributedString *attrPlacholderText = [[NSAttributedString alloc] initWithString:placeholderText attributes:[WPStyleGuide defaultSearchBarTextAttributes:placeholderColor]];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], class, nil] setAttributedPlaceholder:attrPlacholderText];
}

- (void)configureSearchBarForSearchView:(Class)class
{
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], class, nil] setDefaultTextAttributes:[WPStyleGuide defaultSearchBarTextAttributes:[UIColor whiteColor]]];
    
    UISearchBar *searchBar = self.searchController.searchBar;
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
