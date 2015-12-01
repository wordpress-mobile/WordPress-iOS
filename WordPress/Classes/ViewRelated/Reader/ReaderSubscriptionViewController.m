#import "ReaderSubscriptionViewController.h"

#import <SVProgressHUD/SVProgressHUD.h>
#import <WordPressShared/WPFontManager.h>
#import <WordPressShared/UIImage+Util.h>

#import "AccountService.h"
#import "ContextManager.h"
#import "FollowedSitesViewController.h"
#import "ReaderEditableSubscriptionPage.h"
#import "ReaderSiteService.h"
#import "ReaderTopicService.h"
#import "RecommendedTopicsViewController.h"
#import "SubscribedTopicsViewController.h"
#import "WPAccount.h"
#import "WPTableViewCell.h"
#import "WordPress-Swift.h"

static NSString *const SubscribedTopicsPageIdentifier = @"SubscribedTopicsPageIdentifier";
static NSString *const RecommendedTopicsPageIdentifier = @"RecommendedTopicsPageIdentifier";
static NSString *const FollowedSitesPageIdentifier = @"FollowedSitesPageIdentifier";
static const CGFloat TitleViewHeight = 32.0;

@interface ReaderSubscriptionPagePlaceholder : NSObject
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) UIViewController *controller;
@end
@implementation ReaderSubscriptionPagePlaceholder
@end

@interface ReaderSubscriptionViewController ()<UISearchBarDelegate, UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *titleView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, weak) UIPageViewController *pageViewController;
@property (nonatomic, strong) UIBarButtonItem *cancelButton;
@property (nonatomic, assign) NSUInteger currentIndex;
@property (nonatomic, strong) NSMutableArray *controllers;
@property (nonatomic, strong) UIGestureRecognizer *tapOffKeyboardGesture;

@end

@implementation ReaderSubscriptionViewController

#pragma mark - LifeCycle Methods

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        // While referencing self is normally something we try to avoid, these
        // two sync method contain no self references and should be fine to call
        // from within init.
        [self syncTopics];
        [self syncSites];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self configureControllers];
    [self configureSearchBar];
    [self.view addSubview:self.contentView];
    [self configurePageViewController];
    [self configureTitleView];
    [self configureNavbar]; // Configure nav after page view controllers so title is updated.
    [self configureConstraints];

    [WPStyleGuide configureColorsForView:self.view andTableView:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTopicChangedNotification:) name:ReaderTopicDidChangeViaUserInteractionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private Methods

- (void)syncTopics
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];

    ReaderTopicService *topicService = [[ReaderTopicService alloc] initWithManagedObjectContext:context];
    [topicService fetchReaderMenuWithSuccess:^{
        // noop
    } failure:^(NSError *error) {
        DDLogError(@"Error background syncing topics : %@", error);
    }];
}

- (void)syncSites
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];

    ReaderSiteService *service = [[ReaderSiteService alloc] initWithManagedObjectContext:context];
    [service fetchFollowedSitesWithSuccess:^{
        //noop.
    } failure:^(NSError *error) {
        DDLogError(@"Error background syncing followed sites : %@", error);
    }];
}

- (void)keyboardDidShow:(NSNotification *)notification
{
    self.tapOffKeyboardGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard:)];
    self.tapOffKeyboardGesture.cancelsTouchesInView = YES;

    [self.view addGestureRecognizer:self.tapOffKeyboardGesture];
}

- (void)keyboardWillHide:(NSNotificationCenter *)notification
{
    [self.view removeGestureRecognizer:self.tapOffKeyboardGesture];
    self.tapOffKeyboardGesture = nil;
}

- (BOOL)isWPComUser
{
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    return defaultAccount != nil;
}

- (UIViewController *)viewControllerAtIndex:(NSInteger)index
{
    if (index < 0 || index >= [self.controllers count]) {
        return nil;
    }

    return [self controllerForPlaceholder:[self.controllers objectAtIndex:index]];
}

// Does not call controllerForPlaceholder to avoid unnecessary instantiation.
- (NSUInteger)indexOfViewController:(UIViewController *)controller
{
    for (ReaderSubscriptionPagePlaceholder *placeholder in self.controllers) {
        if ([placeholder.controller isEqual:controller]) {
            return [self.controllers indexOfObject:placeholder];
        }
    }
    return NSNotFound;
}

- (UIViewController *)currentViewController
{
    return [self viewControllerAtIndex:self.currentIndex];
}

- (UIViewController *)controllerForPlaceholder:(ReaderSubscriptionPagePlaceholder *)placeholder
{
    if (placeholder.controller) {
        return placeholder.controller;
    }

    // Lazy load controllers.
    if ([placeholder.identifier isEqualToString:SubscribedTopicsPageIdentifier]) {
        __weak __typeof(self) weakSelf  = self;
        SubscribedTopicsViewController *topicsViewController = [[SubscribedTopicsViewController alloc] init];
        topicsViewController.topicListChangedBlock = ^{
            [weakSelf configureNavbar];
        };
        placeholder.controller = topicsViewController;

    } else if ([placeholder.identifier isEqualToString:RecommendedTopicsPageIdentifier]) {
        placeholder.controller = [[RecommendedTopicsViewController alloc] init];

    } else if ([placeholder.identifier isEqualToString:FollowedSitesPageIdentifier]) {
        placeholder.controller = [[FollowedSitesViewController alloc] init];
    }

    return placeholder.controller;
}


#pragma mark - Follow Topic / Site Methods

- (void)followTopicOrSite:(NSString *)topicOrSite
{
    NSString *str = [topicOrSite trim];
    if (![str length]) {
        return;
    }

    NSURL *site = [self URLFromString:str];
    if (site) {
        [self followSite:site];
    } else {
        [self followTopicNamed:str];
    }
}

- (NSURL *)URLFromString:(NSString *)str
{
    // if the string contains space its not a URL
    if ([str rangeOfString:@" "].location != NSNotFound) {
        return nil;
    }

    // if the string does not have either a dot or protocol its not a URL
    if ([str rangeOfString:@"."].location == NSNotFound && [str rangeOfString:@"://"].location == NSNotFound) {
        return nil;
    }

    NSString *urlStr = str;
    if ([urlStr rangeOfString:@"://"].location == NSNotFound) {
        urlStr = [NSString stringWithFormat:@"http://%@", urlStr];
    }

    NSURL *url = [NSURL URLWithString:urlStr];
    if (![url host]) {
        return nil;
    }

    return url;
}

- (void)followSite:(NSURL *)site
{
    __weak __typeof(self) weakSelf  = self;
    ReaderSiteService *service = [[ReaderSiteService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    [service followSiteByURL:site success:^{
        NSString *successMessage = NSLocalizedString(@"Followed", @"User followed a site.");
        [SVProgressHUD showSuccessWithStatus:successMessage];
        
        [weakSelf syncSites];
        [service syncPostsForFollowedSites];
    } failure:^(NSError *error) {
        DDLogError(@"Could not follow site: %@", error);

        NSString *title = NSLocalizedString(@"Could not Follow Site", @"");
        NSString *acceptText = NSLocalizedString(@"OK", @"Label text for the close button on an alert view.");
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                                 message:error.localizedDescription
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        [alertController addCancelActionWithTitle:acceptText handler:nil];
        
        // Note: This viewController might not be visible anymore
        [alertController presentFromRootViewController];
    }];
}

- (void)followTopicNamed:(NSString *)topicName
{
    ReaderTopicService *service = [[ReaderTopicService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    [service followTagNamed:topicName withSuccess:nil failure:^(NSError *error) {
        DDLogError(@"Could not follow topic: %@", error);

        NSString *title = NSLocalizedString(@"Could not Follow Topic", @"");
        NSString *acceptText = NSLocalizedString(@"OK", @"Label text for the close button on an alert view.");
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                                 message:error.localizedDescription
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        [alertController addCancelActionWithTitle:acceptText handler:nil];
        
        // Note: This viewController might not be visible anymore
        [alertController presentFromRootViewController];
    }];
}

#pragma mark - Configuration

- (void)configureControllers
{
    self.controllers = [NSMutableArray array];
    ReaderSubscriptionPagePlaceholder *placeholder;

    // Recommended topics is our default
    placeholder = [[ReaderSubscriptionPagePlaceholder alloc] init];
    placeholder.identifier = RecommendedTopicsPageIdentifier;
    [self.controllers addObject:placeholder];

    if (![self isWPComUser]) {
        return;
    }

    // Followed topics. Insert at index zero so its the first thing shown.
    placeholder = [[ReaderSubscriptionPagePlaceholder alloc] init];
    placeholder.identifier = SubscribedTopicsPageIdentifier;
    [self.controllers insertObject:placeholder atIndex:0];

    // Followed sites
    placeholder = [[ReaderSubscriptionPagePlaceholder alloc] init];
    placeholder.identifier = FollowedSitesPageIdentifier;
    [self.controllers addObject:placeholder];
}

- (void)configureSearchBar
{
    if (![self isWPComUser]) {
        [self.searchBar removeFromSuperview];
        return;
    }

    [self.view addSubview:self.searchBar];
}

- (void)configurePageViewController
{
    [self addChildViewController:self.pageViewController];
    UIView *childView = self.pageViewController.view;
    childView.frame = self.contentView.bounds;
    childView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.contentView addSubview:self.pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];

    UIViewController *startingController = [self viewControllerAtIndex:self.currentIndex];
    [self.pageViewController setViewControllers:@[startingController]
                                      direction:UIPageViewControllerNavigationOrientationHorizontal
                                       animated:NO
                                     completion:nil];
}

- (void)configureTitleView
{
    if ([self.controllers count] < 2) {
        return;
    }
    self.navigationItem.titleView = self.titleView;
}

- (void)configureNavbar
{
    // Update title & page
    NSString *title = [[self currentViewController] title];
    if ([self.controllers count] < 2) {
        self.navigationItem.title = title;
    } else {
        self.pageControl.numberOfPages = [self.controllers count];
        self.pageControl.currentPage = self.currentIndex;
        self.titleLabel.text = title;
    }

    // Edit button
    UIViewController *controller = [self currentViewController];
    if ([controller conformsToProtocol:@protocol(ReaderEditableSubscriptionPage)]) {
        id <ReaderEditableSubscriptionPage> editableSubscriptionPageController = (id <ReaderEditableSubscriptionPage>)controller;
        if ([editableSubscriptionPageController isEditable]) {
            self.navigationItem.rightBarButtonItem = self.editButtonItem;
        } else {
            self.navigationItem.rightBarButtonItem = nil;
        }
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }

    // Cancel button
    if (self.navigationItem.leftBarButtonItem != self.cancelButton) {
        self.navigationItem.leftBarButtonItem = self.cancelButton;
    }
}

- (void)configureConstraints
{
    [self.view removeConstraints:self.view.constraints];
    NSDictionary *views = NSDictionaryOfVariableBindings(_searchBar, _contentView);
    if ([self isWPComUser]) {
        // Layout the search and content.
        [self.view addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:[self horizontalVisualFormatForViewNamed:@"_searchBar"]
                                   options:0
                                   metrics:nil
                                   views:views]];
        [self.view addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"|[_contentView]|"
                                   options:0
                                   metrics:nil
                                   views:views]];

        [self.view addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"V:|[_searchBar][_contentView]|"
                                   options:NSLayoutFormatAlignAllCenterX
                                   metrics:nil
                                   views:views]];

    } else {
        // Just the contentView
        [self.view addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"|[_contentView]|"
                                   options:0
                                   metrics:nil
                                   views:views]];

        [self.view addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"V:|[_contentView]|"
                                   options:0
                                   metrics:nil
                                   views:views]];
    }

    [self.view setNeedsUpdateConstraints];
}

- (NSString *)horizontalVisualFormatForViewNamed:(NSString *)viewName
{
    NSString *format;
    if (IS_IPAD) {
        format = [NSString stringWithFormat:@"[%@(%d)]", viewName, (NSUInteger)WPTableViewFixedWidth];
    } else {
        format = [NSString stringWithFormat:@"|[%@]|", viewName];
    }
    return format;
}

#pragma mark - Accessors

- (UIBarButtonItem *)cancelButton
{
    if (_cancelButton) {
        return _cancelButton;
    }

    _cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"Title for a nav bar button for closing the reader topics subscription feature.")
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(handleCancelButtonTapped:)];
    return _cancelButton;
}

- (UISearchBar *)searchBar
{
    if (_searchBar) {
        return _searchBar;
    }

    // To style the search bar's placeholder, update the appearance proxy using
    // as specific a view hierarchy as possible to avoid collisions.
    NSString *placeholderText = NSLocalizedString(@"Enter a URL or a tag to follow", @"Placeholder text prompting the user to type the name of the URL or tag they would like to follow.");
    NSAttributedString *attrPlacholderText = [[NSAttributedString alloc] initWithString:placeholderText attributes:[WPStyleGuide defaultSearchBarTextAttributes:[WPStyleGuide allTAllShadeGrey]]];
    [[UITextField appearanceWhenContainedInInstancesOfClasses:@[ [self.view class], [UISearchBar class] ]] setAttributedPlaceholder:attrPlacholderText];

    UISearchBar *searchBar = [[UISearchBar alloc] init];
    searchBar.delegate = self;
    searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    searchBar.translucent = NO;
    searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    searchBar.barTintColor = [WPStyleGuide itsEverywhereGrey];
    searchBar.backgroundImage = [[UIImage alloc] init];
    [searchBar setImage:[UIImage imageNamed:@"icon-clear-textfield"] forSearchBarIcon:UISearchBarIconClear state:UIControlStateNormal];
    [searchBar setImage:[UIImage imageNamed:@"icon-reader-search-plus"] forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
    searchBar.accessibilityIdentifier = @"Search";
    // Replace the default "Search" keyboard button with a "Done" button.
    // Apple doesn't expose `returnKeyType` on `UISearchBar` so we'll check to make sure it supports the right protocol, cast and set.
    // Avoids having to walk the view tree looking for an internal textfield, or subclassing UISearchBar to expose the property.
    if ([searchBar conformsToProtocol:@protocol(UITextInputTraits)]) {
        [(id<UITextInputTraits>)searchBar setReturnKeyType:UIReturnKeyDone];
    }

    _searchBar = searchBar;

    return _searchBar;
}

- (UIView *)contentView
{
    if (_contentView) {
        return _contentView;
    }
    UIView *contentView = [[UIView alloc] initWithFrame:self.view.bounds];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    _contentView = contentView;
    return _contentView;
}

- (UIPageViewController *)pageViewController
{
    if (_pageViewController) {
        return _pageViewController;
    }

    UIPageViewController *pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                                               navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                                             options:nil];
    pageViewController.delegate = self;
    pageViewController.dataSource = self;
    _pageViewController = pageViewController;
    _pageViewController.view.accessibilityIdentifier = @"Pager View";
    return _pageViewController;
}

- (UIView *)titleView
{
    if (_titleView) {
        return _titleView;
    }

    UINavigationBar *navBar = self.navigationController.navigationBar;
    CGFloat heightDelta = (CGRectGetHeight(navBar.frame) - TitleViewHeight) / 2.0;
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, heightDelta, 200.0, TitleViewHeight)];
    titleView.backgroundColor = [UIColor clearColor];
    titleView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    _titleView = titleView;

    [_titleView addSubview:self.titleLabel];
    [_titleView addSubview:self.pageControl];

    NSDictionary *views = NSDictionaryOfVariableBindings(_titleLabel, _pageControl);
    [titleView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_titleLabel]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];

    [titleView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_pageControl]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];

    [titleView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_titleLabel(22)][_pageControl(10)]"
                                                                      options:NSLayoutFormatAlignAllCenterX
                                                                      metrics:nil
                                                                        views:views]];

    return _titleView;
}

- (UILabel *)titleLabel
{
    if (_titleLabel) {
        return _titleLabel;
    }

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.font = [WPStyleGuide regularTextFontBold];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel = titleLabel;

    return _titleLabel;
}

- (UIPageControl *)pageControl
{
    if (_pageControl) {
        return _pageControl;
    }
    UIPageControl *pageControl = [[UIPageControl alloc] init];
    pageControl.translatesAutoresizingMaskIntoConstraints = NO;
    pageControl.backgroundColor = [UIColor clearColor];
    pageControl.userInteractionEnabled = NO;
    _pageControl = pageControl;

    return _pageControl;
}

#pragma mark - Action Methods

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    // make the current page editable
    [[self currentViewController] setEditing:editing animated:animated];
    if (editing && [self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
    }
}

- (void)handleCancelButtonTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleTopicChangedNotification:(NSNotification *)notification
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismissKeyboard:(id)sender
{
    [self.searchBar resignFirstResponder];
}

#pragma mark - Search Bar Delegate Methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    if (self.editing) {
        [self setEditing:NO animated:YES];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self followTopicOrSite:searchBar.text];
    searchBar.text = nil;
    [searchBar resignFirstResponder];
}

#pragma mark - Pageview Controller Delegate Methods

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSInteger previousIndex = self.currentIndex - 1;
    return [self viewControllerAtIndex:previousIndex];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSInteger nextIndex = self.currentIndex + 1;
    return [self viewControllerAtIndex:nextIndex];
}

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers
{
    if (self.editing) {
        [self setEditing:NO animated:YES];
    }
    UIViewController *controller = pendingViewControllers[0];
    self.currentIndex = [self indexOfViewController:controller];
    [self configureNavbar];
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    UIViewController *controller = pageViewController.viewControllers[0];
    self.currentIndex = [self indexOfViewController:controller];
    [self configureNavbar];
}

@end
