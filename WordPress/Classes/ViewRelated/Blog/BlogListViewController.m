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

static CGFloat const BLVCHeaderViewLabelPadding = 10.0;

static NSInteger HideAllMinSites = 10;
static NSInteger HideAllSitesThreshold = 6;
static NSTimeInterval HideAllSitesInterval = 2.0;
static NSInteger HideSearchMinSites = 3;

@interface BlogListViewController () <UIViewControllerRestoration,
                                        UIDataSourceModelAssociation,
                                        UITableViewDelegate,
                                        UISearchBarDelegate,
                                        WPNoResultsViewDelegate,
                                        WPSplitViewControllerDetailProvider>

@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UILabel *headerLabel;
@property (nonatomic, strong) WPNoResultsView *noResultsView;
@property (nonatomic, strong) UISearchBar *searchBar;
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

    [self configureStackView];

    [self configureSearchBar];
    [self.stackView addArrangedSubview:self.searchBar];

    [self configureTableView];
    [self.stackView addArrangedSubview:self.tableView];

    self.editButtonItem.accessibilityIdentifier = NSLocalizedString(@"Edit", @"");

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
    [super viewWillDisappear:animated];
    [self unregisterForKeyboardNotifications];
    if (self.searchBar.isFirstResponder) {
        [self.searchBar resignFirstResponder];
    }
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
        [self.searchBar removeFromSuperview];
    } else if (self.searchBar.superview != self.stackView) {
        [self.stackView insertArrangedSubview:self.searchBar atIndex:0];
    }
}

- (void)maybeShowNUX
{
    if (self.dataSource.allBlogsCount > 0) {
        return;
    }
    if (![self defaultWordPressComAccount]) {
        [WPAnalytics track:WPAnalyticsStatLogout];
        [[WordPressAppDelegate sharedInstance] showWelcomeScreenIfNeededAnimated:YES];
    }
}

- (void)updateViewsForCurrentSiteCount
{
    NSUInteger count = self.dataSource.allBlogsCount;
    NSUInteger visibleSitesCount = self.dataSource.visibleBlogsCount;

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
    NSUInteger count = self.dataSource.allBlogsCount;

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

- (void)configureStackView
{
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.spacing = 0;
    [self.view addSubview:stackView];
    [self.view pinSubviewToAllEdges:stackView];
    _stackView = stackView;
}

- (void)configureTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self.dataSource;
    [self.tableView registerClass:[WPBlogTableViewCell class] forCellReuseIdentifier:[WPBlogTableViewCell reuseIdentifier]];
    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.accessibilityIdentifier = NSLocalizedString(@"Blogs", @"");
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;

    self.tableView.tableFooterView = [UIView new];
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
}

- (void)configureSearchBar
{
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
    self.searchBar.delegate = self;

    [WPStyleGuide configureSearchBar:self.searchBar];
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

    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, insets.left, keyboardHeight, insets.right);
    self.tableView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, insets.left, keyboardHeight, insets.right);
}

- (void)keyboardWillHide:(NSNotification*)notification
{
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsZero;
    self.tableView.contentInset = UIEdgeInsetsZero;
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
    if (self.tableView.isEditing) {
        return UITableViewCellEditingStyleNone;
    } else {
        return UITableViewCellEditingStyleDelete;
    }
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Blog *blog = [self.dataSource blogAtIndexPath:indexPath];
    NSMutableArray *actions = [NSMutableArray array];
    __typeof(self) __weak weakSelf = self;

    if ([blog supports:BlogFeatureRemovable]) {
        UITableViewRowAction *removeAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                                                                title:NSLocalizedString(@"Remove", @"Removes a self hosted site from the app")
                                                                              handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
                                                                                  [ReachabilityUtils onAvailableInternetConnectionDo:^{
                                                                                      [weakSelf showRemoveSiteAlertForIndexPath:indexPath];
                                                                                  }];
                                                                              }];
        removeAction.backgroundColor = [WPStyleGuide errorRed];
        [actions addObject:removeAction];
    } else {
        if (blog.visible) {
            UITableViewRowAction *hideAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                                                                  title:NSLocalizedString(@"Hide", @"Hides a site from the site picker list")
                                                                                handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
                                                                                    [ReachabilityUtils onAvailableInternetConnectionDo:^{
                                                                                        [weakSelf hideBlogAtIndexPath:indexPath];
                                                                                    }];
                                                                                }];
            hideAction.backgroundColor = [WPStyleGuide grey];
            [actions addObject:hideAction];
        } else {
            UITableViewRowAction *unhideAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                                                                    title:NSLocalizedString(@"Unhide", @"Unhides a site from the site picker list")
                                                                                  handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
                                                                                      [ReachabilityUtils onAvailableInternetConnectionDo:^{
                                                                                          [weakSelf unhideBlogAtIndexPath:indexPath];
                                                                                      }];
                                                                                  }];
            unhideAction.backgroundColor = [WPStyleGuide validGreen];
            [actions addObject:unhideAction];
        }
    }

    return actions;
}

- (void)showRemoveSiteAlertForIndexPath:(NSIndexPath *)indexPath
{
    Blog *blog = [self.dataSource blogAtIndexPath:indexPath];
    NSString *blogDisplayName = blog.settings.name.length ? blog.settings.name : blog.displayURL;
    NSString *model = [[UIDevice currentDevice] localizedModel];
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to continue?\n All site data for %@ will be removed from your %@.", @"Title for the remove site confirmation alert, first %@ will be replaced with the blog url, second %@ will be replaced with iPhone/iPad/iPod Touch"), blogDisplayName, model];
    NSString *cancelTitle = NSLocalizedString(@"Cancel", nil);
    NSString *destructiveTitle = NSLocalizedString(@"Remove Site", @"Button to remove a site from the app");

    UIAlertControllerStyle alertStyle = [UIDevice isPad] ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:message
                                                                      preferredStyle:alertStyle];

    [alertController addCancelActionWithTitle:cancelTitle handler:nil];
    [alertController addDestructiveActionWithTitle:destructiveTitle handler:^(UIAlertAction *action) {
        [self confirmRemoveSiteForIndexPath:indexPath];
    }];
    [self presentViewController:alertController animated:YES completion:nil];
    [self.tableView setEditing:NO animated:YES];
}

- (void)confirmRemoveSiteForIndexPath:(NSIndexPath *)indexPath
{
    Blog *blog = [self.dataSource blogAtIndexPath:indexPath];
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    [blogService removeBlog:blog];
    [self.tableView reloadData];
}

- (void)hideBlogAtIndexPath:(NSIndexPath *)indexPath
{
    Blog *blog = [self.dataSource blogAtIndexPath:indexPath];
    [self setVisible:NO forBlog:blog];
    [self.tableView setEditing:NO animated:YES];
}

- (void)unhideBlogAtIndexPath:(NSIndexPath *)indexPath
{
    Blog *blog = [self.dataSource blogAtIndexPath:indexPath];
    [self setVisible:YES forBlog:blog];
    [self.tableView setEditing:NO animated:YES];
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
    return [WPBlogTableViewCell cellHeight];
}

# pragma mark - UISearchBar delegate methods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    self.dataSource.searchQuery = searchText;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    self.dataSource.searching = YES;
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    self.dataSource.searching = NO;
    [searchBar setShowsCancelButton:NO animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
    self.searchBar.text = nil;
    self.dataSource.searching = NO;
    self.dataSource.searchQuery = nil;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
}

# pragma mark - Navigation Bar

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    // We need to do this to dismiss actions on a cell that might have been swipped
    // and it's in an open state before tapping the Edit button
    if (editing && self.tableView.isEditing) {
        [self.tableView setEditing:NO animated:NO];
    }
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];
    self.dataSource.editing = editing;
    [self toggleRightBarButtonItems:!editing];

    if (editing) {
        [self.searchBar removeFromSuperview];
        [self.addSiteAlertController dismissViewControllerAnimated:YES completion:nil];
        [self updateHeaderSize];
        self.tableView.tableHeaderView = self.headerView;

        self.firstHide = nil;
        self.hideCount = 0;
        self.noResultsView.hidden = YES;
    }
    else {
        self.tableView.tableHeaderView = nil;
        [self updateViewsForCurrentSiteCount];
        [self updateSearchVisibility];
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
    if(!visible && self.dataSource.allBlogsCount > HideAllMinSites) {
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
    if (self.dataSource.allBlogsCount == 0) {
        UIAlertController *addSiteAlertController = [self makeAddSiteAlertController];
        addSiteAlertController.popoverPresentationController.sourceView = self.view;
        addSiteAlertController.popoverPresentationController.sourceRect = [self.view convertRect:noResultsView.button.frame
                                                                                        fromView:noResultsView];
        addSiteAlertController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;

        [self presentViewController:addSiteAlertController animated:YES completion:nil];
        self.addSiteAlertController = addSiteAlertController;
    } else if (self.dataSource.visibleBlogsCount == 0) {
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
