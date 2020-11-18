#import "BlogListViewController.h"
#import "WordPress-Swift.h"

static CGFloat const BLVCHeaderViewLabelPadding = 10.0;

static NSInteger HideAllMinSites = 10;
static NSInteger HideAllSitesThreshold = 6;
static NSTimeInterval HideAllSitesInterval = 2.0;
static NSInteger HideSearchMinSites = 3;

@interface BlogListViewController () <UIViewControllerRestoration,
                                        UIDataSourceModelAssociation,
                                        UITableViewDelegate,
                                        UISearchBarDelegate,
                                        NoResultsViewControllerDelegate,
                                        WPSplitViewControllerDetailProvider>

@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UILabel *headerLabel;
@property (nonatomic, strong) NoResultsViewController *noResultsViewController;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic,   weak) UIAlertController *addSiteAlertController;
@property (nonatomic, strong) UIBarButtonItem *addSiteButton;

@property (nonatomic, strong) BlogDetailsViewController *blogDetailsViewController;
@property (nonatomic, strong) BlogListDataSource *dataSource;

@property (nonatomic) NSDate *firstHide;
@property (nonatomic) NSInteger hideCount;
@property (nonatomic) BOOL visible;
@property (nonatomic) BOOL isSyncing;
@end

@implementation BlogListViewController

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    return [[WPTabBarController sharedInstance] blogListViewController];
}

- (instancetype)init
{
    return [self initWithMeScenePresenter:[MeScenePresenter new]];
}

- (instancetype)initWithMeScenePresenter:(id<ScenePresenter>)meScenePresenter
{
    self = [super init];
    
    if (self) {
        self.restorationIdentifier = NSStringFromClass([self class]);
        self.restorationClass = [self class];
        _meScenePresenter = meScenePresenter;
        
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

    self.addSiteButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                       target:self
                                                                       action:@selector(addSite)];

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

    [self registerForAccountChangeNotification];
    [self registerForPostSignUpNotifications];
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
    [self setAddSiteBarButtonItem];
    [self updateCurrentBlogSelection];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self createUserActivity];
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
    if (self.isEditing) {
        return;
    }
    
    if (self.dataSource.visibleBlogsCount <= HideSearchMinSites) {
        // Hide the search bar if there's only a few blogs
        [self.searchBar removeFromSuperview];
    } else if (self.searchBar.superview != self.stackView) {
        [self.stackView insertArrangedSubview:self.searchBar atIndex:0];
    }
}

- (void)maybeShowNUX
{
    NSInteger blogCount = self.dataSource.allBlogsCount;
    BOOL isLoggedIn = AccountHelper.isLoggedIn;

    if (blogCount > 0 && !isLoggedIn) {
        return;
    }
    
    if (![self defaultWordPressComAccount]) {
        [[WordPressAppDelegate shared] showWelcomeScreenIfNeededAnimated:YES];
        return;
    }
}

- (void)updateViewsForCurrentSiteCount
{
    NSUInteger count = self.dataSource.allBlogsCount;
    NSUInteger visibleSitesCount = self.dataSource.visibleBlogsCount;
    
    // Ensure No Results VC is not shown. Will be shown later if necessary.
    [self.noResultsViewController removeFromView];
    
    // If the user has sites, but they're all hidden...
    if (count > 0 && visibleSitesCount == 0 && !self.isEditing) {
        [self showNoResultsViewForAllSitesHidden];
    } else {
        [self showNoResultsViewForSiteCount:count];
    }
    
    [self updateSplitViewAppearanceForSiteCount:count];
}

- (void)addNoResultsToView
{
    [self instantiateNoResultsViewControllerIfNeeded];

    [self.view layoutIfNeeded];
    [self addChildViewController:self.noResultsViewController];

    [self.tableView addSubview:self.noResultsViewController.view];
    self.noResultsViewController.view.frame = self.tableView.bounds;
    [self.noResultsViewController didMoveToParentViewController:self];
}

- (void)showNoResultsViewForSiteCount:(NSUInteger)siteCount
{
    // If we've gone from no results to having just one site, the user has
    // added a new site so we should auto-select it
    if (self.noResultsViewController.beingPresented && siteCount == 1) {
        [self.noResultsViewController removeFromView];
        [self bypassBlogListViewController];
    }

    [self instantiateNoResultsViewControllerIfNeeded];
    
    // If we have no sites, show the No Results VC.
    if (siteCount == 0) {
        [self.noResultsViewController configureWithTitle:NSLocalizedString(@"Create a new site for your business, magazine, or personal blog; or connect an existing WordPress installation.", "Text shown when the account has no sites.")
                                         attributedTitle:nil
                                       noConnectionTitle:nil
                                             buttonTitle:NSLocalizedString(@"Add new site","Title of button to add a new site.")
                                                subtitle:nil
                                    noConnectionSubtitle:nil
                                      attributedSubtitle:nil
                         attributedSubtitleConfiguration:nil
                                                   image:@"mysites-nosites"
                                           subtitleImage:nil
                                           accessoryView:nil];
        [self addNoResultsToView];
    }
}

- (void)showNoResultsViewForAllSitesHidden
{
    [self instantiateNoResultsViewControllerIfNeeded];
    
    NSUInteger count = self.dataSource.allBlogsCount;
    
    NSString *singularTitle = NSLocalizedString(@"You have 1 hidden WordPress site.", @"Message informing the user that all of their sites are currently hidden (singular)");
    
    NSString *multipleTitle = [NSString stringWithFormat:NSLocalizedString(@"You have %lu hidden WordPress sites.", @"Message informing the user that all of their sites are currently hidden (plural)"), count];
    NSString *multipleSubtitle = NSLocalizedString(@"To manage them here, set them to visible.", @"Prompt asking user to make sites visible in order to use them in the app (plural)");
    
    NSString *buttonTitle = NSLocalizedString(@"Change Visibility", @"Button title to edit visibility of sites.");
    NSString *imageName = @"mysites-nosites";
    
    if (count == 1) {
        [self.noResultsViewController configureWithTitle:singularTitle
                                         attributedTitle:nil
                                       noConnectionTitle:nil
                                             buttonTitle:buttonTitle
                                                subtitle:singularTitle
                                    noConnectionSubtitle:nil
                                      attributedSubtitle:nil
                         attributedSubtitleConfiguration:nil
                                                   image:imageName
                                           subtitleImage:nil
                                           accessoryView:nil];
    } else {
        [self.noResultsViewController configureWithTitle:multipleTitle
                                         attributedTitle:nil
                                       noConnectionTitle:nil
                                             buttonTitle:buttonTitle
                                                subtitle:multipleSubtitle
                                    noConnectionSubtitle:nil
                                      attributedSubtitle:nil
                         attributedSubtitleConfiguration:nil
                                                   image:imageName
                                           subtitleImage:nil
                                           accessoryView:nil];
    }

    [self addNoResultsToView];
    
}

- (void)updateSplitViewAppearanceForSiteCount:(NSUInteger)siteCount
{
    BOOL hasSites = (siteCount > 0);

    // If we have no results, set the split view to full width
    WPSplitViewController *splitViewController = (WPSplitViewController *)self.splitViewController;
    if ([splitViewController isKindOfClass:[WPSplitViewController class]]) {
        splitViewController.dimsDetailViewControllerAutomatically = hasSites;
        splitViewController.wpPrimaryColumnWidth = (hasSites) ? WPSplitViewControllerPrimaryColumnWidthNarrow
                                                              : WPSplitViewControllerPrimaryColumnWidthFull;
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
    if (self.isSyncing) {
        return;
    }

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

    if (!defaultAccount) {
        [self handleSyncEnded];
        return;
    }

    if (![self.tableView.refreshControl isRefreshing]) {
        [self.tableView.refreshControl beginRefreshing];
    }
    self.isSyncing = YES;
    __weak __typeof(self) weakSelf = self;
    void (^completionBlock)(void) = ^() {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf handleSyncEnded];
        });
    };

    context = [[ContextManager sharedInstance] newDerivedContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];

    [context performBlock:^{
        [blogService syncBlogsForAccount:defaultAccount success:^{
            completionBlock();
        } failure:^(NSError * _Nonnull error) {
            completionBlock();
        }];
    }];
}

- (void)handleSyncEnded
{
    self.isSyncing = NO;
    [self.tableView.refreshControl endRefreshing];
}

- (void)removeBlogItemsFromSpotlight:(Blog *)blog {
    if (!blog) {
        return;
    }

    if (blog.dotComID && [blog.dotComID intValue] > 0) {
        [SearchManager.shared deleteAllSearchableItemsFromDomain: blog.dotComID.stringValue];
    } else if (blog.xmlrpc && !blog.xmlrpc.isEmpty) {
        [SearchManager.shared deleteAllSearchableItemsFromDomain: blog.xmlrpc];
    } else {
        DDLogWarn(@"Unable to delete all indexed spotlight items for blog: %@", blog.logDescription);
    }
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
        _headerLabel.textColor = [UIColor murielText];
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

- (void)presentInterfaceForAddingNewSiteFrom:(UIView *)sourceView
{
    [self.navigationController popToRootViewControllerAnimated:YES];

    [self showAddSiteAlertFrom:sourceView];
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
    return [WPStyleGuide preferredStatusBarStyle];
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
    self.tableView.accessibilityIdentifier = @"Blogs";
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;

    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(syncBlogs) forControlEvents:UIControlEventValueChanged];
    self.tableView.refreshControl = refreshControl;

    self.tableView.tableFooterView = [UIView new];
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
}

- (void)configureSearchBar
{
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
    self.searchBar.delegate = self;

    [WPStyleGuide configureSearchBar:self.searchBar];
}

- (void)instantiateNoResultsViewControllerIfNeeded
{
    if (!self.noResultsViewController) {
        self.noResultsViewController = [NoResultsViewController controller];
        self.noResultsViewController.delegate = self;
    }
}

#pragma mark - Notifications
- (void)registerForPostSignUpNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(launchSiteCreation)
                                                 name:NSNotification.PSICreateSite
                                               object:nil];


    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showLoginControllerForAddingSelfHostedSite)
                                                 name:NSNotification.PSIAddSelfHosted
                                               object:nil];
}

- (void)registerForAccountChangeNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(wordPressComAccountChanged:)
                                                 name:WPAccountDefaultWordPressComAccountChangedNotification
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
    self.tableView.contentInset = UIEdgeInsetsMake(self.view.safeAreaInsets.top, insets.left, keyboardHeight, insets.right);
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
    [self.tableView reloadData];
    [self setEditing:NO];
    [self updateSearchVisibility];
}

#pragma mark - Table view delegate

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
        removeAction.backgroundColor = [UIColor murielError];
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
            hideAction.backgroundColor = [UIColor murielNeutral30];
            [actions addObject:hideAction];
        } else {
            UITableViewRowAction *unhideAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                                                                    title:NSLocalizedString(@"Unhide", @"Unhides a site from the site picker list")
                                                                                  handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
                                                                                      [ReachabilityUtils onAvailableInternetConnectionDo:^{
                                                                                          [weakSelf unhideBlogAtIndexPath:indexPath];
                                                                                      }];
                                                                                  }];
            unhideAction.backgroundColor = [UIColor murielSuccess];
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
    [self removeBlogItemsFromSpotlight:blog];
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
    [self removeBlogItemsFromSpotlight:blog];
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

        if (![blog isEqual:self.selectedBlog]) {
            [[PushNotificationsManager shared] deletePendingLocalNotifications];
        }

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
        self.blogDetailsViewController = [self makeBlogDetailsViewController];
        self.blogDetailsViewController.blog = selectedBlog;

        if (![self splitViewControllerIsHorizontallyCompact]) {
            WPSplitViewController *splitViewController = (WPSplitViewController *)self.splitViewController;
            [self showDetailViewController:[(UIViewController <WPSplitViewControllerDetailProvider> *)self.blogDetailsViewController initialDetailViewControllerForSplitView:splitViewController] sender:self];
        }
    }

    /// Issue #7284:
    /// Prevents pushing BlogDetailsViewController, if it was already in the hierarchy.
    ///
    if ([self.navigationController.viewControllers containsObject:self.blogDetailsViewController]) {
        return;
    }

    [self.navigationController pushViewController:self.blogDetailsViewController animated:animated];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
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
    [self toggleAddSiteButton:!editing];

    if (editing) {
        [self.searchBar removeFromSuperview];
        [self.addSiteAlertController dismissViewControllerAnimated:YES completion:nil];
        [self updateHeaderSize];
        self.tableView.tableHeaderView = self.headerView;

        self.firstHide = nil;
        self.hideCount = 0;
    } else {
        self.tableView.tableHeaderView = nil;
        [self updateViewsForCurrentSiteCount];
        [self updateSearchVisibility];
    }
}

- (void)toggleAddSiteButton:(BOOL)enabled
{
    self.addSiteButton.enabled = enabled;
}

- (void)setAddSiteBarButtonItem
{
    if (self.dataSource.allBlogsCount == 0) {
        [self addMeButtonToNavigationBarWithEmail:[[self defaultWordPressComAccount] email] meScenePresenter:self.meScenePresenter];
    }
    else {
        self.navigationItem.rightBarButtonItem = self.addSiteButton;
    }
}

- (void)addSite
{
    [self showAddSiteAlertFrom:self.addSiteButton];
}

- (WPAccount *)defaultWordPressComAccount
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    return [accountService defaultWordPressComAccount];
}

- (void)showLoginControllerForAddingSelfHostedSite
{
    [self setEditing:NO animated:NO];
    [WordPressAuthenticator showLoginForSelfHostedSite:self];
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
                                                                         [[ContextManager sharedInstance] saveContext:context];
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
    [[WordPressAppDelegate shared] trackLogoutIfNeeded];
    [self maybeShowNUX];
    [self updateSearchVisibility];
    [self updateViewsForCurrentSiteCount];
    [self validateBlogDetailsViewController];
}

#pragma mark - NoResultsViewControllerDelegate

- (void)actionButtonPressed {
    [self showAddSiteAlertFrom:self.noResultsViewController.actionButton];
}

#pragma mark - View Delegate Helper

- (void)showAddSiteAlertFrom:(id)source
{
    if (self.dataSource.allBlogsCount > 0 && self.dataSource.visibleBlogsCount == 0) {
        [self setEditing:YES animated:YES];
    } else {
        AddSiteAlertFactory *factory = [AddSiteAlertFactory new];
        UIAlertController *alertController = [factory makeAddSiteAlertWithCanCreateWPComSite:[self defaultWordPressComAccount]
                                                                             createWPComSite:^{
            [self launchSiteCreation];
        } addSelfHostedSite:^{
            [self showLoginControllerForAddingSelfHostedSite];
        }];
        
        if ([source isKindOfClass:[UIView class]]) {
            UIView *sourceView = (UIView *)source;
            alertController.popoverPresentationController.sourceView = sourceView;
            alertController.popoverPresentationController.sourceRect = sourceView.bounds;
        } else if ([source isKindOfClass:[UIBarButtonItem class]]) {
            alertController.popoverPresentationController.barButtonItem = source;
        }
        alertController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;

        [self presentViewController:alertController animated:YES completion:nil];
        self.addSiteAlertController = alertController;
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
