#import "BlogListViewController.h"
#import "WordPressAppDelegate.h"
#import "UIImageView+Gravatar.h"
#import "BlogDetailsViewController.h"
#import "WPTableViewCell.h"
#import "WPBlogTableViewCell.h"
#import "ContextManager.h"
#import "Blog.h"
#import "WPAccount.h"
#import "AccountService.h"
#import "BlogService.h"
#import "TodayExtensionService.h"
#import "WPTabBarController.h"
#import "WPFontManager.h"
#import "UILabel+SuggestSize.h"
#import "WordPress-Swift.h"
#import "WPGUIConstants.h"
#import "CreateNewBlogViewController.h"

static NSString *const BlogCellIdentifier = @"BlogCell";
static CGFloat const BLVCHeaderViewLabelPadding = 10.0;
static CGFloat const BLVCSiteRowHeight = 74.0;

static NSInteger HideAllMinSites = 10;
static NSInteger HideAllSitesThreshold = 6;
static NSTimeInterval HideAllSitesInterval = 2.0;
static NSInteger HideSearchMinSites = 3;

@interface BlogListViewController () <UIViewControllerRestoration,
                                        UIDataSourceModelAssociation,
                                        UITableViewDelegate,
                                        UISearchResultsUpdating,
                                        UISearchControllerDelegate,
                                        WPNoResultsViewDelegate,
                                        WPSplitViewControllerDetailProvider>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UILabel *headerLabel;
@property (nonatomic, strong) WPNoResultsView *noResultsView;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic,   weak) UIAlertController *addSiteAlertController;
@property (nonatomic, strong) UIBarButtonItem *addSiteButton;

@property (nonatomic, strong) BlogDetailsViewController *blogDetailsViewController;
@property (nonatomic, strong) BlogListDataSource *dataSource;

@property (nonatomic) NSDate *firstHide;
@property (nonatomic) NSInteger hideCount;
@property (nonatomic) BOOL visible;

@end

@implementation BlogListViewController

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    return [[WPTabBarController sharedInstance] blogListViewController];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.restorationIdentifier = NSStringFromClass([self class]);
        self.restorationClass = [self class];
        [self configureDataSource];
        [self configureNavigationBar];
    }
    return self;
}

- (void)configureDataSource
{
    self.dataSource = [BlogListDataSource new];
    __weak __typeof(self) weakSelf = self;
    self.dataSource.visibilityChanged = ^(Blog *blog, BOOL visible) {
        [weakSelf setVisible:visible forBlog:blog];
    };
    self.dataSource.dataChanged = ^{
        if (weakSelf.visible) {
            [weakSelf dataChanged];
        }
    };
}

- (void)configureNavigationBar
{
    // show 'Switch Site' for the next page's back button
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Switch Site", @"")
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:nil
                                                                  action:nil];
    [self.navigationItem setBackBarButtonItem:backButton];
    
    self.addSiteButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-post-add"]
                                                                                    style:UIBarButtonItemStylePlain
                                                                                   target:self
                                                                                   action:@selector(addSite)];

    self.navigationItem.rightBarButtonItem = self.addSiteButton;

    self.navigationItem.title = NSLocalizedString(@"My Sites", @"");
}

- (NSString *)modelIdentifierForElementAtIndexPath:(NSIndexPath *)indexPath inView:(UIView *)view
{
    if (!indexPath || !view) {
        return nil;
    }

    // Preserve objectID
    NSManagedObject *managedObject = [self.dataSource blogAtIndexPath:indexPath];
    return [[managedObject.objectID URIRepresentation] absoluteString];
}

- (NSIndexPath *)indexPathForElementWithModelIdentifier:(NSString *)identifier inView:(UIView *)view
{
    if (!identifier || !view) {
        return nil;
    }

    // Map objectID back to indexPath
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    NSManagedObjectID *objectID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:identifier]];
    if (!objectID) {
        return nil;
    }

    NSError *error = nil;
    Blog *blog = (Blog *)[context existingObjectWithID:objectID error:&error];
    if (error || !blog) {
        return nil;
    }

    NSIndexPath *indexPath = [self.dataSource indexPathForBlog:blog];

    return indexPath;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.tableView];
    [self.view pinSubviewToAllEdges:self.tableView];

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    self.editButtonItem.accessibilityIdentifier = NSLocalizedString(@"Edit", @"");

    [self configureTableView];
    [self configureSearchController];
    [self configureNoResultsView];

    [self registerForAccountChangeNotification];
    [self registerForBlogCreationNotification];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self registerForKeyboardNotifications];

    self.visible = YES;
    [self.tableView reloadData];
    [self updateEditButton];
    [self updateSearchVisibility];
    [self maybeShowNUX];
    [self updateViewsForCurrentSiteCount];
    [self validateBlogDetailsViewController];
    [self syncBlogs];

    [self updateCurrentBlogSelection];
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.searchController.active = NO;
    [super viewWillDisappear:animated];
    [self unregisterForKeyboardNotifications];
    self.visible = NO;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        if (self.tableView.tableHeaderView == self.headerView) {
            [self updateHeaderSize];
            
            // this forces the tableHeaderView to resize
            self.tableView.tableHeaderView = self.headerView;
        }
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self updateCurrentBlogSelection];
    }];
}


- (void)updateEditButton
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    if ([blogService blogCountForWPComAccounts] > 0) {
        self.navigationItem.leftBarButtonItem = self.editButtonItem;
    } else {
        self.navigationItem.leftBarButtonItem = nil;
    }
}

- (void)updateSearchVisibility
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    if ([blogService blogCountForAllAccounts] <= HideSearchMinSites) {
        // Hide the search bar if there's only a few blogs
        self.tableView.tableHeaderView = nil;
    } else {
        [self addSearchBarTableHeaderView];
    }
}

- (void)maybeShowNUX
{
    if ([self countForAllBlogs] > 0) {
        return;
    }
    if (![self defaultWordPressComAccount]) {
        [WPAnalytics track:WPAnalyticsStatLogout];
        [[WordPressAppDelegate sharedInstance] showWelcomeScreenIfNeededAnimated:YES];
    }
}

- (void)updateViewsForCurrentSiteCount
{
    NSUInteger count = [self countForAllBlogs];
    NSUInteger visibleSitesCount = [self countForVisibleBlogs];

    // If the user has sites, but they're all hidden...
    if (count > 0 && visibleSitesCount == 0 && !self.isEditing) {
        [self showNoResultsViewForAllSitesHidden];
    } else {
        [self showNoResultsViewForSiteCount:count];
        [self updateSplitViewAppearanceForSiteCount:count];
    }
}

- (void)showNoResultsViewForSiteCount:(NSUInteger)siteCount
{
    // If we've gone from no results to having just one site, the user has
    // added a new site so we should auto-select it
    if (!self.noResultsView.hidden && siteCount == 1) {
        [self bypassBlogListViewController];
    }

    self.noResultsView.hidden = siteCount > 0;

    if (!self.noResultsView.hidden) {
        self.noResultsView.titleText = NSLocalizedString(@"You don't have any WordPress sites yet.", @"Title shown when the user has no sites.");
        self.noResultsView.messageText = NSLocalizedString(@"Would you like to start one?", @"Prompt asking user whether they'd like to create a new site if they don't already have one.");
        self.noResultsView.buttonTitle = NSLocalizedString(@"Create Site", nil);
    }
}

- (void)showNoResultsViewForAllSitesHidden
{
    NSUInteger count = [self countForAllBlogs];

    if (count == 1) {
        self.noResultsView.titleText = NSLocalizedString(@"You have 1 hidden WordPress site.", "Message informing the user that all of their sites are currently hidden (singular)");
        self.noResultsView.messageText = NSLocalizedString(@"To manage it here, set it to visible.", @"Prompt asking user to make sites visible in order to use them in the app (singular)");
    } else {
        self.noResultsView.titleText = [NSString stringWithFormat:NSLocalizedString(@"You have %lu hidden WordPress sites.", "Message informing the user that all of their sites are currently hidden (plural)"), count];
        self.noResultsView.messageText = NSLocalizedString(@"To manage them here, set them to visible.", @"Prompt asking user to make sites visible in order to use them in the app (plural)");
    }

    self.noResultsView.buttonTitle = NSLocalizedString(@"Change Visibility", "Button title to edit visibility of sites.");

    self.noResultsView.hidden = NO;
}

- (void)updateSplitViewAppearanceForSiteCount:(NSUInteger)siteCount
{
    BOOL hasSites = (siteCount > 0);

    // If we have no results, set the split view to full width
    WPSplitViewController *splitViewController = (WPSplitViewController *)self.splitViewController;
    if ([splitViewController isKindOfClass:[WPSplitViewController class]]) {
        splitViewController.dimsDetailViewControllerAutomatically = hasSites;
        splitViewController.wpPrimaryColumnWidth = (hasSites) ? WPSplitViewControllerPrimaryColumnWidthNarrow : WPSplitViewControllerPrimaryColumnWidthFull;
    }
}

- (void)validateBlogDetailsViewController
{
    // Nil out our blog details VC reference if the blog no longer exists
    if (self.blogDetailsViewController && ![self.dataSource indexPathForBlog:self.blogDetailsViewController.blog]) {
        self.blogDetailsViewController = nil;
    }
}

- (NSUInteger)countForAllBlogs
{
    return self.dataSource.allBlogsCount;
}

- (NSUInteger)countForVisibleBlogs
{
    return self.dataSource.visibleBlogsCount;
}

- (NSUInteger)countForPredicate:(NSPredicate *)predicate
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:BlogEntityName];
    request.predicate = predicate;

    NSUInteger count = [context countForFetchRequest:request error:nil];
    if (count == NSNotFound) {
        count = 0;
    }

    return count;
}

- (void)syncBlogs
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
    [context performBlock:^{
        AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
        BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
        WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

        if (defaultAccount) {
            [blogService syncBlogsForAccount:defaultAccount success:nil failure:nil];
        }
    }];
}

#pragma mark - Header methods

- (UIView *)headerView
{
    if (!_headerView) {
        _headerView = [[UIView alloc] initWithFrame:CGRectZero];
        [_headerView addSubview:self.headerLabel];
    }

    return _headerView;
}

- (UILabel *)headerLabel
{
    if (!_headerLabel) {
        _headerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _headerLabel.numberOfLines = 0;
        _headerLabel.textAlignment = NSTextAlignmentCenter;
        _headerLabel.textColor = [WPStyleGuide allTAllShadeGrey];
        _headerLabel.font = [WPFontManager systemRegularFontOfSize:14.0];
        _headerLabel.text = NSLocalizedString(@"Select which sites will be shown in the site picker.", @"Blog list page edit mode header label");
    }

    return _headerLabel;
}

- (void)updateHeaderSize
{
    CGFloat labelWidth = CGRectGetWidth(self.view.bounds) - 2 * BLVCHeaderViewLabelPadding;

    CGSize labelSize = [self.headerLabel suggestSizeForString:self.headerLabel.text width:labelWidth];
    self.headerLabel.frame = CGRectMake(BLVCHeaderViewLabelPadding, BLVCHeaderViewLabelPadding, labelWidth, labelSize.height);
    self.headerView.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.bounds), labelSize.height + (2 * BLVCHeaderViewLabelPadding));
}

#pragma mark - Public methods

- (void)presentInterfaceForAddingNewSite
{
    [self.navigationController popToRootViewControllerAnimated:YES];
    [self addSite];
}

- (BOOL)shouldBypassBlogListViewControllerWhenSelectedFromTabBar
{
    return self.dataSource.displayedBlogsCount == 1;
}

- (void)bypassBlogListViewController
{
    if ([self shouldBypassBlogListViewControllerWhenSelectedFromTabBar]) {
        // We do a delay of 0.0 so that way this doesn't kick off until the next run loop.
        [self performSelector:@selector(selectFirstSite) withObject:nil afterDelay:0.0];
    }
}

- (void)selectFirstSite
{
    [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
}

- (void)updateCurrentBlogSelection
{
    if (self.splitViewControllerIsHorizontallyCompact) {
        [self.tableView deselectSelectedRowWithAnimation:YES];
    } else {
        if (self.selectedBlog) {
            NSIndexPath *indexPath = [self.dataSource indexPathForBlog:self.selectedBlog];
            if (indexPath) {
                [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
        }
    }
}

#pragma mark - Configuration

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)configureTableView
{
    self.tableView.delegate = self;
    self.tableView.dataSource = self.dataSource;
    [self.tableView registerClass:[WPBlogTableViewCell class] forCellReuseIdentifier:BlogCellIdentifier];
    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.accessibilityIdentifier = NSLocalizedString(@"Blogs", @"");

    self.tableView.tableFooterView = [UIView new];
}

- (void)configureSearchController
{
    // Required for insets to work out correctly when the search bar becomes active
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.definesPresentationContext = YES;

    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.dimsBackgroundDuringPresentation = NO;

    [self addSearchBarTableHeaderView];

    self.searchController.delegate = self;
    self.searchController.searchResultsUpdater = self;

    [WPStyleGuide configureSearchBar:self.searchController.searchBar];
}

- (void)addSearchBarTableHeaderView
{
    if (!self.tableView.tableHeaderView) {
        // Required to work around a bug where the search bar was extending a
        // grey background above the top of the tableview, which was visible when
        // pulling down further than offset zero
        SearchWrapperView *wrapperView = [SearchWrapperView new];
        [wrapperView addSubview:self.searchController.searchBar];
        wrapperView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.searchController.searchBar.bounds.size.height);
        self.tableView.tableHeaderView = wrapperView;
    }
}

- (CGFloat)searchBarHeight {
    return CGRectGetHeight(self.searchController.searchBar.bounds) + self.topLayoutGuide.length;
}

- (void)configureNoResultsView
{
    self.noResultsView = [WPNoResultsView noResultsViewWithTitle:nil
                                                         message:nil
                                                   accessoryView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"theme-empty-results"]]
                                                     buttonTitle:nil];
    [self.tableView addSubview:self.noResultsView];
    [self.noResultsView setTranslatesAutoresizingMaskIntoConstraints:NO];

    [self.tableView pinSubviewAtCenter:self.noResultsView];
    [self.noResultsView layoutIfNeeded];

    self.noResultsView.hidden = YES;

    self.noResultsView.delegate = self;
}

#pragma mark - Notifications

- (void)registerForAccountChangeNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(wordPressComAccountChanged:)
                                                 name:WPAccountDefaultWordPressComAccountChangedNotification
                                               object:nil];
}

- (void)registerForBlogCreationNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newWordPressComBlogCreated:)
                                                 name:NewWPComBlogCreatedNotification
                                               object:nil];
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)unregisterForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    CGRect keyboardFrame = [self localKeyboardFrameFromNotification:notification];
    CGFloat keyboardHeight = CGRectGetMaxY(self.tableView.frame) - keyboardFrame.origin.y;

    UIEdgeInsets insets = self.tableView.contentInset;

    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake([self searchBarHeight], insets.left, keyboardHeight, insets.right);
    self.tableView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, insets.left, keyboardHeight, insets.right);
}

- (void)keyboardWillHide:(NSNotification*)notification
{
    CGFloat tabBarHeight = self.tabBarController.tabBar.bounds.size.height;

    UIEdgeInsets insets = self.tableView.contentInset;
    insets.top = self.topLayoutGuide.length;
    insets.bottom = tabBarHeight;

    self.tableView.contentInset = insets;

    if (self.searchController.active) {
        insets.top = [self searchBarHeight];
    }

    self.tableView.scrollIndicatorInsets = insets;
}

-(CGRect)localKeyboardFrameFromNotification:(NSNotification *)notification
{
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];

    // Convert the frame from window coordinates
    return [self.view convertRect:keyboardFrame fromView:nil];
}

- (void)wordPressComApiDidLogin:(NSNotification *)notification
{
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)wordPressComApiDidLogout:(NSNotification *)notification
{
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)wordPressComAccountChanged:(NSNotification *)notification
{
    [self setEditing:NO];
    [self updateSearchVisibility];
}

- (void)newWordPressComBlogCreated:(NSNotification *)notification
{
    Blog *blog = notification.userInfo[NewWPComBlogCreatedNotificationBlogUserInfoKey];

    if (blog) {
        NSIndexPath *indexPath = [self.dataSource indexPathForBlog:blog];
        if (indexPath) {
            [self.tableView flashRowAtIndexPath:indexPath
                                 scrollPosition:UITableViewScrollPositionMiddle
                                     completion:^{
                                         if (![self splitViewControllerIsHorizontallyCompact]) {
                                             [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
                                         }
                                     }];
        }
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor whiteColor];
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NSLocalizedString(@"Remove", @"Button label when removing a blog");
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    // If we have more than one section, show a 2px separator unless the section has a title.
    NSString *sectionTitle = nil;
    if ([tableView.dataSource respondsToSelector:@selector(tableView:titleForHeaderInSection:)]) {
        sectionTitle = [tableView.dataSource tableView:tableView titleForHeaderInSection:section];
    }
    if (section > 0 && [sectionTitle length] == 0) {
        return 2;
    }
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Blog *blog = [self.dataSource blogAtIndexPath:indexPath];
    if (self.tableView.isEditing) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        UISwitch *visibleSwitch = (UISwitch *)cell.accessoryView;
        if (visibleSwitch && [visibleSwitch isKindOfClass:[UISwitch class]]) {
            visibleSwitch.on = !visibleSwitch.on;
            [self setVisible:visibleSwitch.on forBlog:blog];
        }
        return;
    } else {
        blog.visible = YES;

        RecentSitesService *recentSites = [RecentSitesService new];
        [recentSites touchBlog:blog];

        self.selectedBlog = blog;
    }
}

- (void)setSelectedBlog:(Blog *)selectedBlog
{
    [self setSelectedBlog:selectedBlog animated:[self isViewLoaded]];
}

- (void)setSelectedBlog:(Blog *)selectedBlog animated:(BOOL)animated
{
    if (selectedBlog != _selectedBlog || !_blogDetailsViewController) {
        _selectedBlog = selectedBlog;

        self.blogDetailsViewController = [[BlogDetailsViewController alloc] init];
        self.blogDetailsViewController.blog = selectedBlog;

        if (![self splitViewControllerIsHorizontallyCompact]) {
            WPSplitViewController *splitViewController = (WPSplitViewController *)self.splitViewController;
            [self showDetailViewController:[(UIViewController <WPSplitViewControllerDetailProvider> *)self.blogDetailsViewController initialDetailViewControllerForSplitView:splitViewController] sender:self];
        }
    }

    [self.navigationController pushViewController:self.blogDetailsViewController animated:animated];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return BLVCSiteRowHeight;
}

# pragma mark - UISearchController delegate methods

- (void)willPresentSearchController:(UISearchController *)searchController
{
    self.dataSource.searching = YES;
}

- (void)willDismissSearchController:(UISearchController *)searchController
{
    self.dataSource.searching = NO;
    self.searchController.searchBar.text = nil;
}

- (void)didDismissSearchController:(UISearchController *)searchController
{
    UIEdgeInsets insets = self.tableView.scrollIndicatorInsets;
    insets.top = self.topLayoutGuide.length;
    self.tableView.scrollIndicatorInsets = insets;
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    self.dataSource.searchQuery = searchController.searchBar.text;
}

# pragma mark - Navigation Bar

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];
    self.dataSource.editing = editing;
    [self toggleRightBarButtonItems:!editing];

    if (editing) {
        [self.addSiteAlertController dismissViewControllerAnimated:YES completion:nil];
        [self updateHeaderSize];
        self.tableView.tableHeaderView = self.headerView;

        self.firstHide = nil;
        self.hideCount = 0;
        self.noResultsView.hidden = YES;
    }
    else {
        self.tableView.tableHeaderView = self.searchController.searchBar;
        [self updateViewsForCurrentSiteCount];
    }
}

- (void)toggleRightBarButtonItems:(BOOL)enabled
{
    for (UIBarButtonItem *buttonItem in self.navigationItem.rightBarButtonItems) {
        buttonItem.enabled = enabled;
    }
}

- (void)addSite
{
    UIAlertController *addSiteAlertController = [self makeAddSiteAlertController];
    addSiteAlertController.popoverPresentationController.barButtonItem = self.addSiteButton;

    [self presentViewController:addSiteAlertController animated:YES completion:nil];
    self.addSiteAlertController = addSiteAlertController;
}

- (UIAlertController *)makeAddSiteAlertController
{
    UIAlertController *addSiteAlertController = [UIAlertController alertControllerWithTitle:nil
                                                                                    message:nil
                                                                             preferredStyle:UIAlertControllerStyleActionSheet];
    if ([self defaultWordPressComAccount]) {
        UIAlertAction *addNewWordPressAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Create WordPress.com site", @"Create WordPress.com site button")
                                                                        style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction *action) {
                                                                          [self showAddNewWordPressController];
                                                                      }];
        [addSiteAlertController addAction:addNewWordPressAction];
    }

    UIAlertAction *addSiteAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Add self-hosted site", @"Add self-hosted site button")
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
                                                              [self showLoginControllerForAddingSelfHostedSite];
                                                          }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel button")
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil];

    [addSiteAlertController addAction:addSiteAction];
    [addSiteAlertController addAction:cancel];

    return addSiteAlertController;
}

- (WPAccount *)defaultWordPressComAccount
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    return [accountService defaultWordPressComAccount];
}

- (void)showAddNewWordPressController
{
    [self setEditing:NO animated:NO];
    CreateNewBlogViewController *createNewBlogViewController = [[CreateNewBlogViewController alloc] init];
    [self.navigationController presentViewController:createNewBlogViewController animated:YES completion:nil];
}

- (void)showLoginControllerForAddingSelfHostedSite
{
    [self setEditing:NO animated:NO];
    [SigninHelpers showSigninForSelfHostedSite:self];
}

- (void)setVisible:(BOOL)visible forBlog:(Blog *)blog
{
    if(!visible && [self countForAllBlogs] > HideAllMinSites) {
        if (self.hideCount == 0) {
            self.firstHide = [NSDate date];
        }
        self.hideCount += 1;

        if (self.hideCount >= HideAllSitesThreshold && (self.firstHide.timeIntervalSinceNow * -1) < HideAllSitesInterval) {
            
            NSString *message = NSLocalizedString(@"Would you like to hide all WordPress.com Sites?",
                                                  @"Message offering to hide all WPCom Sites");

            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Hide All Sites", @"Hide All Sites")
                                                                                     message:message
                                                                              preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel")
                                                                   style:UIAlertActionStyleCancel
                                                                 handler:^(UIAlertAction *action){}];
            
            UIAlertAction *hideAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Hide All", @"Hide All")
                                                                   style:UIAlertActionStyleDestructive
                                                                 handler:^(UIAlertAction *action){
                                                                     NSManagedObjectContext *context = [[ContextManager sharedInstance] newDerivedContext];
                                                                     [context performBlock:^{
                                                                         AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
                                                                         WPAccount *account = [accountService defaultWordPressComAccount];
                                                                         [accountService setVisibility:visible forBlogs:[account.blogs allObjects]];
                                                                         [[ContextManager sharedInstance] saveDerivedContext:context];
                                                                     }];
                                                                 }];
            [alertController addAction:cancelAction];
            [alertController addAction:hideAction];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    }
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    [accountService setVisibility:visible forBlogs:@[blog]];
}

#pragma mark - Data Listener

- (void)dataChanged
{
    [self.tableView reloadData];
    [self updateEditButton];
    [self maybeShowNUX];
    [self updateViewsForCurrentSiteCount];
    [self validateBlogDetailsViewController];
}

#pragma mark - WPNoResultsViewDelegate

- (void)didTapNoResultsView:(WPNoResultsView *)noResultsView
{
    if ([self countForAllBlogs] == 0) {
        UIAlertController *addSiteAlertController = [self makeAddSiteAlertController];
        addSiteAlertController.popoverPresentationController.sourceView = self.view;
        addSiteAlertController.popoverPresentationController.sourceRect = [self.view convertRect:noResultsView.button.frame
                                                                                        fromView:noResultsView];
        addSiteAlertController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;

        [self presentViewController:addSiteAlertController animated:YES completion:nil];
        self.addSiteAlertController = addSiteAlertController;
    } else if ([self countForVisibleBlogs] == 0) {
        [self setEditing:YES animated:YES];
    }
}

#pragma mark - WPSplitViewControllerDetailProvider

- (UIViewController *)initialDetailViewControllerForSplitView:(WPSplitViewController *)splitView
{
    if (self.dataSource.displayedBlogsCount == 0 || !self.blogDetailsViewController) {
        UIViewController *emptyViewController = [UIViewController new];
        [WPStyleGuide configureColorsForView:emptyViewController.view andTableView:nil];
        return emptyViewController;
    } else {
        return [(UIViewController <WPSplitViewControllerDetailProvider> *)self.blogDetailsViewController initialDetailViewControllerForSplitView:splitView];
    }
}

@end
