#import "AbstractPostListViewController.h"

#import "AbstractPostListViewControllerSubclass.h"
#import "AbstractPost.h"
#import "EditSiteViewController.h"
#import "PostPreviewViewController.h"
#import "PostSettingsSelectionViewController.h"
#import "UIView+Subviews.h"
#import "WordPressAppDelegate.h"

const NSTimeInterval PostsControllerRefreshInterval = 300; // 5 minutes
const NSTimeInterval PostSearchBarAnimationDuration = 0.2; // seconds
const NSInteger HTTPErrorCodeForbidden = 403;
const NSInteger PostsFetchRequestBatchSize = 10;
const NSInteger PostsLoadMoreThreshold = 4;
const CGFloat PostsSearchBarWidth = 280.0;
const CGFloat PostsSearchBariPadWidth = 600.0;
const CGSize PreferredFiltersPopoverContentSize = {320.0, 220.0};
const CGFloat SearchWrapperViewPortraitHeight = 64.0;
const CGFloat SearchWrapperViewLandscapeHeight = 44.0;
const CGFloat DefaultHeightForFooterView = 44.0;

@implementation AbstractPostListViewController

#pragma mark - Lifecycle Methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.recentlyTrashedPostIDs = [NSMutableArray array];
    self.tableView = self.postListViewController.tableView;
    self.refreshControl = self.postListViewController.refreshControl;
    [self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];

    [self configureFilters];
    [self configureCellsForLayout];
    [self configureTableView];
    [self configureFooterView];
    [self configureSyncHelper];
    [self configureNavbar];
    [self configureAuthorFilter];
    [self configureSearchController];
    [self configureSearchBar];
    [self configureSearchWrapper];
    [self configureTableViewHandler];

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self configureNoResultsView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self automaticallySyncIfAppropriate];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.searchController.active = NO;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    if ([UIDevice isPad]) {
        return;
    }

    CGRect bounds = self.view.window.frame;
    CGFloat width = CGRectGetWidth(bounds);
    CGFloat height = CGRectGetHeight(bounds);
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        width = MIN(width, height);
    } else {
        width = MAX(width, height);
    }

    [self.tableViewHandler refreshCachedRowHeightsForWidth:width];

    if (self.searchWrapperViewHeightConstraint.constant > 0) {
        self.searchWrapperViewHeightConstraint.constant = [self heightForSearchWrapperView];
    }
}


#pragma mark - Configuration

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (CGFloat)heightForFooterView
{
    return DefaultHeightForFooterView;
}

- (void)configureFilters
{
    self.postListFilters = [PostListFilter newPostListFilters];
}

- (void)configureNavbar
{
    // IMPORTANT: this code makes sure that the back button in WPPostViewController doesn't show
    // this VC's title.
    //
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:[NSString string] style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = backButton;

    UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.rightBarButtonView];
    [WPStyleGuide setRightBarButtonItemWithCorrectSpacing:rightBarButtonItem forNavigationItem:self.navigationItem];

    self.navigationItem.titleView = self.filterButton;
    [self updateFilterTitle];
}

- (void)configureCellsForLayout
{
    AssertSubclassMethod();
}

- (void)configureTableView
{
    AssertSubclassMethod();
}

- (void)configureFooterView
{
    self.postListFooterView = (PostListFooterView *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([PostListFooterView class]) owner:nil options:nil] firstObject];
    [self.postListFooterView showSpinner:NO];
    CGRect frame = self.postListFooterView.frame;
    frame.size.height = [self heightForFooterView];
    self.postListFooterView.frame = frame;
    self.tableView.tableFooterView = self.postListFooterView;
}

- (void)configureTableViewHandler
{
    self.tableViewHandler = [[WPTableViewHandler alloc] initWithTableView:self.tableView];
    self.tableViewHandler.cacheRowHeights = YES;
    self.tableViewHandler.delegate = self;
    self.tableViewHandler.updateRowAnimation = UITableViewRowAnimationNone;
}

- (void)configureSyncHelper
{
    self.syncHelper = [[WPContentSyncHelper alloc] init];
    self.syncHelper.delegate = self;
}

- (void)configureNoResultsView
{
    if (!self.isViewLoaded) {
        return;
    }

    if (!self.noResultsView) {
        self.noResultsView = [[WPNoResultsView alloc] init];
        self.noResultsView.delegate = self;
    }

    if ([self.tableViewHandler.resultsController.fetchedObjects count] > 0) {
        [self.noResultsView removeFromSuperview];
        self.postListFooterView.hidden = NO;
        return;
    }
    self.postListFooterView.hidden = YES;

    // Refresh the NoResultsView Properties
    self.noResultsView.titleText        = self.noResultsTitleText;
    self.noResultsView.messageText      = self.noResultsMessageText;
    self.noResultsView.accessoryView    = self.noResultsAccessoryView;
    self.noResultsView.buttonTitle      = self.noResultsButtonText;

    // Only add and animate no results view if it isn't already
    // in the table view
    if (![self.noResultsView isDescendantOfView:self.tableView]) {
        [self.tableView addSubviewWithFadeAnimation:self.noResultsView];
    } else {
        [self.noResultsView centerInSuperview];
    }

    [self.tableView sendSubviewToBack:self.noResultsView];
}

- (NSString *)noResultsTitleText
{
    AssertSubclassMethod();
    return nil;
}

- (NSString *)noResultsMessageText
{
    AssertSubclassMethod();
    return nil;
}

- (UIView *)noResultsAccessoryView {
    if (self.syncHelper.isSyncing) {
        if (!self.animatedBox) {
            self.animatedBox = [WPAnimatedBox new];
        }
        return self.animatedBox;
    }
    return [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"penandink"]];
}

- (NSString *)noResultsButtonText
{
    AssertSubclassMethod();
    return nil;
}

- (void)configureAuthorFilter
{
    AssertSubclassMethod();
}

- (void)configureSearchController
{
    self.searchController = [[WPSearchController alloc] initWithSearchResultsController:nil];
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.hidesNavigationBarDuringPresentation = YES;
    self.searchController.delegate = self;
    self.searchController.searchResultsUpdater = self;
}

- (void)configureSearchBar
{
    [self configureSearchBarPlaceholder];

    UISearchBar *searchBar = self.searchController.searchBar;
    searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    searchBar.accessibilityIdentifier = @"Search";
    searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    searchBar.backgroundImage = [[UIImage alloc] init];
    searchBar.tintColor = [WPStyleGuide grey]; // cursor color
    searchBar.translucent = NO;
    [searchBar setImage:[UIImage imageNamed:@"icon-clear-textfield"] forSearchBarIcon:UISearchBarIconClear state:UIControlStateNormal];
    [searchBar setImage:[UIImage imageNamed:@"icon-post-list-search"] forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];

    [self configureSearchBarForSearchView];
}

- (void)configureSearchBarForSearchView
{
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], [self class], nil] setDefaultTextAttributes:[WPStyleGuide defaultSearchBarTextAttributes:[UIColor whiteColor]]];

    UISearchBar *searchBar = self.searchController.searchBar;
    searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    searchBar.barStyle = UIBarStyleBlack;
    searchBar.barTintColor = [WPStyleGuide wordPressBlue];
    searchBar.showsCancelButton = YES;

    [self.searchWrapperView addSubview:searchBar];

    NSDictionary *views = NSDictionaryOfVariableBindings(searchBar);
    NSDictionary *metrics = @{@"searchbarWidth":@(PostsSearchBariPadWidth)};
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

- (void)configureSearchBarPlaceholder
{
    // Adjust color depending on where the search bar is being presented.
    UIColor *placeholderColor = [WPStyleGuide wordPressBlue];
    NSString *placeholderText = NSLocalizedString(@"Search", @"Placeholder text for the search bar on the post screen.");
    NSAttributedString *attrPlacholderText = [[NSAttributedString alloc] initWithString:placeholderText attributes:[WPStyleGuide defaultSearchBarTextAttributes:placeholderColor]];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], [self class], nil] setAttributedPlaceholder:attrPlacholderText];
}

- (void)configureSearchWrapper
{
    self.searchWrapperView.backgroundColor = [WPStyleGuide wordPressBlue];
}

- (NSDictionary *)propertiesForAnalytics
{
    return @{
             @"type":[self postTypeToSync],
             @"filter":self.currentPostListFilter.title,
             };
}

#pragma mark - Actions

- (IBAction)refresh:(id)sender
{
    [self syncItemsWithUserInteraction:YES];
    [WPAnalytics track:WPAnalyticsStatPostListPullToRefresh withProperties:[self propertiesForAnalytics]];
}

- (IBAction)handleAddButtonTapped:(id)sender
{
    [self createPost];
}

- (IBAction)handleSearchButtonTapped:(id)sender
{
    [self toggleSearch];
}

- (void)didTapNoResultsView:(WPNoResultsView *)noResultsView
{
    [WPAnalytics track:WPAnalyticsStatPostListNoResultsButtonPressed withProperties:[self propertiesForAnalytics]];
    if ([self currentPostListFilter].filterType == PostListStatusFilterScheduled) {
        NSInteger index = [self indexForFilterWithType:PostListStatusFilterDraft];
        [self setCurrentFilterIndex:index];
        return;
    }
    [self createPost];
}

- (IBAction)didTapFilterButton:(id)sender
{
    if (self.postFilterPopoverController) {
        return;
    }
    [self displayFilters];
}

#pragma mark - Syncing

- (void)automaticallySyncIfAppropriate
{
    // Only automatically refresh if the view is loaded and visible on the screen
    if (self.isViewLoaded == NO || self.view.window == nil) {
        DDLogVerbose(@"View is not visible and will not check for auto refresh.");
        return;
    }

    // Do not start auto-sync if connection is down
    WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedInstance];
    if (appDelegate.connectionAvailable == NO) {
        [self configureNoResultsView];
        return;
    }

    NSDate *lastSynced = self.blog.lastPostsSync;
    if (lastSynced == nil || ABS([lastSynced timeIntervalSinceNow]) > PostsControllerRefreshInterval) {
        // Update in the background
        [self syncItemsWithUserInteraction:NO];
    } else {
        [self configureNoResultsView];
    }
}

- (void)syncItemsWithUserInteraction:(BOOL)userInteraction
{
    [self.syncHelper syncContentWithUserInteraction:userInteraction];
    [self configureNoResultsView];
}

- (void)setHasMore:(BOOL)hasMore forFilter:(PostListFilter *)filter
{
    filter.hasMore = hasMore;
}


#pragma mark - Sync Helper Delegate Methods

- (NSString *)postTypeToSync
{
    // Subclasses should override.
    return PostServiceTypeAny;
}

- (void)syncHelper:(WPContentSyncHelper *)syncHelper syncContentWithUserInteraction:(BOOL)userInteraction success:(void (^)(BOOL))success failure:(void (^)(NSError *))failure
{
    if ([self.recentlyTrashedPostIDs count]) {
        [self.recentlyTrashedPostIDs removeAllObjects];
        [self updateAndPerformFetchRequestRefreshingCachedRowHeights];
    }

    PostListFilter *filter = [self currentPostListFilter];
    NSArray *postStatus = filter.statuses;
    NSNumber *author = [self shouldShowOnlyMyPosts] ? self.blog.account.userID : nil;
    __weak __typeof(self) weakSelf = self;
    PostService *postService = [[PostService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    [postService syncPostsOfType:[self postTypeToSync] withStatuses:postStatus byAuthor:author forBlog:self.blog success:^(BOOL hasMore){
        if  (success) {
            [weakSelf setHasMore:hasMore forFilter:filter];
            success(hasMore);
        }
    } failure:^(NSError *error) {
        if (failure) {
            failure(error);
        }
        if (userInteraction) {
            [self handleSyncFailure:error];
        }
    }];
}

- (void)syncHelper:(WPContentSyncHelper *)syncHelper syncMoreWithSuccess:(void (^)(BOOL))success failure:(void (^)(NSError *))failure
{
    [WPAnalytics track:WPAnalyticsStatPostListLoadedMore withProperties:[self propertiesForAnalytics]];
    [self.postListFooterView showSpinner:YES];
    PostListFilter *filter = [self currentPostListFilter];
    NSArray *postStatus = filter.statuses;
    NSNumber *author = [self shouldShowOnlyMyPosts] ? self.blog.account.userID : nil;
    __weak __typeof(self) weakSelf = self;
    PostService *postService = [[PostService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    [postService loadMorePostsOfType:[self postTypeToSync] withStatuses:postStatus byAuthor:author forBlog:self.blog success:^(BOOL hasMore){
        if (success) {
            [weakSelf setHasMore:hasMore forFilter:filter];
            success(hasMore);
        }
    } failure:^(NSError *error) {
        if (failure) {
            failure(error);
        }
        [self handleSyncFailure:error];
    }];
}

- (void)syncContentEnded
{
    [self.refreshControl endRefreshing];
    [self.postListFooterView showSpinner:NO];

    self.blog.lastPostsSync = [NSDate date];

    [self.noResultsView removeFromSuperview];
    if ([[self.tableViewHandler.resultsController fetchedObjects] count] == 0) {
        // This is a special case.  Core data can be a bit slow about notifying
        // NSFetchedResultsController delegates about changes to the fetched results.
        // To compensate, call configureNoResultsView after a short delay.
        // It will be redisplayed if necessary.
        [self performSelector:@selector(configureNoResultsView) withObject:self afterDelay:0.1];
    }
}

- (void)handleSyncFailure:(NSError *)error
{
    if ([error.domain isEqualToString:WPXMLRPCClientErrorDomain]) {
        if (error.code == HTTPErrorCodeForbidden) {
            [self promptForPassword];
            return;
        }
    }
    [WPError showNetworkingAlertWithError:error title:NSLocalizedString(@"Unable to Sync", @"Title of error prompt shown when a sync the user initiated fails.")];
}

- (void)promptForPassword
{
    NSString *message = NSLocalizedString(@"The username or password stored in the app may be out of date. Please re-enter your password in the settings and try again.", @"");
    [WPError showAlertWithTitle:NSLocalizedString(@"Unable to Connect", @"") message:message];

    // bad login/pass combination
    EditSiteViewController *editSiteViewController = [[EditSiteViewController alloc] initWithBlog:self.blog];
    editSiteViewController.isCancellable = YES;

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editSiteViewController];
    navController.navigationBar.translucent = NO;

    if (IS_IPAD) {
        navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
    }

    [self presentViewController:navController animated:YES completion:nil];
}


#pragma mark - TableView Handler Delegate Methods

- (NSString *)entityName
{
    AssertSubclassMethod();
    return nil;
}

- (NSManagedObjectContext *)managedObjectContext
{
    return [[ContextManager sharedInstance] mainContext];
}

- (NSFetchRequest *)fetchRequest
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
    fetchRequest.predicate = [self predicateForFetchRequest];
    fetchRequest.sortDescriptors = [self sortDescriptorsForFetchRequest];
    fetchRequest.fetchBatchSize = PostsFetchRequestBatchSize;
    return fetchRequest;
}

- (NSArray *)sortDescriptorsForFetchRequest
{
    // Ascending only for scheduled posts/pages.
    BOOL ascending = self.currentPostListFilter.filterType == PostListStatusFilterScheduled;
    NSSortDescriptor *sortDescriptorLocal = [NSSortDescriptor sortDescriptorWithKey:@"metaIsLocal" ascending:NO];
    NSSortDescriptor *sortDescriptorImmediately = [NSSortDescriptor sortDescriptorWithKey:@"metaPublishImmediately" ascending:NO];
    NSSortDescriptor *sortDescriptorDate = [NSSortDescriptor sortDescriptorWithKey:@"date_created_gmt" ascending:ascending];
    return @[sortDescriptorLocal, sortDescriptorImmediately, sortDescriptorDate];
}

- (void)updateAndPerformFetchRequest
{
    NSAssert([NSThread isMainThread], @"AbstractPostListViewController Error: NSFetchedResultsController accessed in BG");
    NSPredicate *predicate = [self predicateForFetchRequest];
    NSArray *sortDescriptors = [self sortDescriptorsForFetchRequest];
    NSError *error = nil;
    [self.tableViewHandler.resultsController.fetchRequest setPredicate:predicate];
    [self.tableViewHandler.resultsController.fetchRequest setSortDescriptors:sortDescriptors];
    [self.tableViewHandler.resultsController performFetch:&error];
    if (error) {
        DDLogError(@"Error fetching posts after updating the fetch request predicate: %@", error);
    }
}

- (void)updateAndPerformFetchRequestRefreshingCachedRowHeights
{
    [self updateAndPerformFetchRequest];

    CGFloat width = CGRectGetWidth(self.tableView.bounds);
    [self.tableViewHandler refreshCachedRowHeightsForWidth:width];

    [self.tableView reloadData];
    [self configureNoResultsView];
}

- (NSPredicate *)predicateForFetchRequest
{
    AssertSubclassMethod();
    return nil;
}


#pragma mark - Table View Handling

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AssertSubclassMethod();
}

- (void)tableViewDidChangeContent:(UITableView *)tableView
{
    // After any change, make sure that the no results view is properly
    // configured.
    [self configureNoResultsView];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Are we approaching the end of the table?
    if ((indexPath.section + 1 == self.tableView.numberOfSections) &&
        (indexPath.row + PostsLoadMoreThreshold >= [self.tableView numberOfRowsInSection:indexPath.section])) {

        // Only 3 rows till the end of table
        if ([self currentPostListFilter].hasMore) {
            [self.syncHelper syncMoreContent];
        }
    }
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    AssertSubclassMethod();
}


#pragma mark - Actions

- (void)publishPost:(AbstractPost *)apost
{
    [WPAnalytics track:WPAnalyticsStatPostListPublishAction withProperties:[self propertiesForAnalytics]];
    apost.status = PostStatusPublish;
    apost.dateCreated = [NSDate date];
    PostService *postService = [[PostService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    [postService uploadPost:apost
                    success:nil
                    failure:^(NSError *error) {
                        if([error code] == HTTPErrorCodeForbidden) {
                            [self promptForPassword];
                        } else {
                            [WPError showXMLRPCErrorAlert:error];
                        }
                        [self syncItemsWithUserInteraction:NO];
                    }];
}

- (void)viewPost:(AbstractPost *)apost
{
    [WPAnalytics track:WPAnalyticsStatPostListViewAction withProperties:[self propertiesForAnalytics]];
    apost = ([apost hasRevision]) ? apost.revision : apost;
    PostPreviewViewController *controller = [[PostPreviewViewController alloc] initWithPost:apost shouldHideStatusBar:NO];
    controller.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)deletePost:(AbstractPost *)apost
{
    [WPAnalytics track:WPAnalyticsStatPostListTrashAction withProperties:[self propertiesForAnalytics]];
    NSNumber *postID = apost.postID;
    [self.recentlyTrashedPostIDs addObject:postID];

    // Update the fetch request *before* making the service call.
    [self updateAndPerformFetchRequest];

    NSIndexPath *indexPath = [self.tableViewHandler.resultsController indexPathForObject:apost];
    [self.tableViewHandler invalidateCachedRowHeightAtIndexPath:indexPath];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];

    PostService *postService = [[PostService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    [postService trashPost:apost
                   success:nil
                   failure:^(NSError *error) {
                       if([error code] == HTTPErrorCodeForbidden) {
                           [self promptForPassword];
                       } else {
                           [WPError showXMLRPCErrorAlert:error];
                       }

                       [self.recentlyTrashedPostIDs removeObject:postID];
                       [self.tableViewHandler invalidateCachedRowHeightAtIndexPath:indexPath];
                       [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                   }];
}

- (void)restorePost:(AbstractPost *)apost
{
    [WPAnalytics track:WPAnalyticsStatPostListRestoreAction withProperties:[self propertiesForAnalytics]];
    // if the post was recently deleted, update the status helper and reload the cell to display a spinner
    NSNumber *postID = apost.postID;
    NSManagedObjectID *postObjectID = apost.objectID;

    [self.recentlyTrashedPostIDs removeObject:postID];

    PostService *postService = [[PostService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    [postService restorePost:apost
                     success:^() {
                         // Make sure the post still exists.
                         NSError *err;
                         AbstractPost *post = (AbstractPost *)[self.managedObjectContext existingObjectWithID:postObjectID error:&err];
                         if (err) {
                             DDLogError(@"%@", err);
                         }
                         if (!post) {
                             return;
                         }

                         // If the post was restored, see if it appears in the current filter.
                         // If not, prompt the user to let it know under which filter it appears.
                         PostListFilter *filter = [self filterThatDisplaysPostsWithStatus:post.status];
                         if ([filter isEqual:[self currentPostListFilter]]) {
                             return;
                         }
                         [self promptThatPostRestoredToFilter:filter];
                     }
                     failure:^(NSError *error) {
                         if([error code] == 403) {
                             [self promptForPassword];
                         } else {
                             [WPError showXMLRPCErrorAlert:error];
                         }
                         [self.recentlyTrashedPostIDs addObject:postID];
                     }];
}

- (void)promptThatPostRestoredToFilter:(PostListFilter *)filter
{
    AssertSubclassMethod();
}


#pragma mark - Instance Methods

#pragma mark - Post Actions

- (void)createPost
{
    AssertSubclassMethod();
}

#pragma mark - Search related

- (void)toggleSearch
{
    self.searchController.active = !self.searchController.active;
}

- (CGFloat)heightForSearchWrapperView
{
    if ([UIDevice isPad]) {
        return SearchWrapperViewPortraitHeight;
    }
    return UIDeviceOrientationIsPortrait(self.interfaceOrientation) ? SearchWrapperViewPortraitHeight : SearchWrapperViewLandscapeHeight;
}

- (BOOL)isSearching
{
    return self.searchController.isActive && [[self currentSearchTerm] length]> 0;
}

- (NSString *)currentSearchTerm
{
    return self.searchController.searchBar.text;
}


#pragma mark - Filter related

- (BOOL)canFilterByAuthor
{
    return [self.blog isMultiAuthor] && self.blog.account.userID && [self.blog isHostedAtWPcom];
}

- (BOOL)shouldShowOnlyMyPosts
{
    PostAuthorFilter filter = [self currentPostAuthorFilter];
    return filter == PostAuthorFilterMine;
}

- (PostAuthorFilter)currentPostAuthorFilter
{
    return PostAuthorFilterEveryone;
}

- (void)setCurrentPostAuthorFilter:(PostAuthorFilter)filter
{
    // Noop. The default implementation is read only.
    // Subclasses may override the getter and setter for their own filter storage.
}

- (PostListFilter *)currentPostListFilter
{
    return self.postListFilters[[self currentFilterIndex]];
}

- (PostListFilter *)filterThatDisplaysPostsWithStatus:(NSString *)postStatus
{
    for (PostListFilter *filter in self.postListFilters) {
        if ([filter.statuses containsObject:postStatus]) {
            return filter;
        }
    }
    // The draft filter is the catch all by convention.
    return [self.postListFilters objectAtIndex:[self indexForFilterWithType:PostListStatusFilterDraft]];
}

- (NSInteger)indexForFilterWithType:(PostListStatusFilter)filterType
{
    NSInteger index = [self.postListFilters indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        PostListFilter *filter = (PostListFilter *)obj;
        return filter.filterType == filterType;
    }];
    return index;
}

- (NSString *)keyForCurrentListStatusFilter
{
    AssertSubclassMethod();
    return nil;
}

- (NSInteger)currentFilterIndex
{
    NSNumber *filter = [[NSUserDefaults standardUserDefaults] objectForKey:[self keyForCurrentListStatusFilter]];
    if (!filter || [filter integerValue] >= [self.postListFilters count]) {
        return 0; // first item is the default
    }
    return [filter integerValue];
}

- (void)setCurrentFilterIndex:(NSInteger)newIndex
{
    NSInteger index = [self currentFilterIndex];
    if (newIndex == index) {
        return;
    }
    [WPAnalytics track:WPAnalyticsStatPostListStatusFilterChanged withProperties:[self propertiesForAnalytics]];
    [[NSUserDefaults standardUserDefaults] setObject:@(newIndex) forKey:[self keyForCurrentListStatusFilter]];
    [NSUserDefaults resetStandardUserDefaults];

    [self.recentlyTrashedPostIDs removeAllObjects];
    [self updateFilterTitle];
    [self updateAndPerformFetchRequestRefreshingCachedRowHeights];
}

- (void)updateFilterTitle
{
    [self.filterButton setAttributedTitleForTitle:[self currentPostListFilter].title];
}

- (void)displayFilters
{
    NSMutableArray *titles = [NSMutableArray array];
    for (PostListFilter *filter in self.postListFilters) {
        [titles addObject:filter.title];
    }
    NSDictionary *dict = @{
                           SettingsSelectionDefaultValueKey   : [self.postListFilters firstObject],
                           SettingsSelectionTitleKey          : NSLocalizedString(@"Filters", @"Title of the list of post status filters."),
                           SettingsSelectionTitlesKey         : titles,
                           SettingsSelectionValuesKey         : self.postListFilters,
                           SettingsSelectionCurrentValueKey   : [self currentPostListFilter]
                           };

    PostSettingsSelectionViewController *controller = [[PostSettingsSelectionViewController alloc] initWithStyle:UITableViewStylePlain andDictionary:dict];
    controller.onItemSelected = ^(NSDictionary *selectedValue) {
        if (self.postFilterPopoverController) {
            [self.postFilterPopoverController dismissPopoverAnimated:YES];
            self.postFilterPopoverController = nil;
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        [self setCurrentFilterIndex:[self.postListFilters indexOfObject:selectedValue]];
    };
    controller.onCancel = ^() {
        [self handleFilterSelectionCanceled];
    };

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    if ([UIDevice isPad]) {
        [self displayFilterPopover:navController];
    } else {
        [self displayFilterModal:navController];
    }
}

- (void)displayFilterPopover:(UIViewController *)controller
{
    controller.preferredContentSize = PreferredFiltersPopoverContentSize;

    CGRect titleRect = self.navigationItem.titleView.frame;
    titleRect = [self.navigationController.view convertRect:titleRect fromView:self.navigationItem.titleView.superview];

    self.postFilterPopoverController = [[UIPopoverController alloc] initWithContentViewController:controller];
    self.postFilterPopoverController.delegate = self;
    [self.postFilterPopoverController presentPopoverFromRect:titleRect
                                                      inView:self.navigationController.view
                                    permittedArrowDirections:UIPopoverArrowDirectionAny
                                                    animated:YES];
}

- (void)displayFilterModal:(UIViewController *)controller
{
    controller.modalPresentationStyle = UIModalPresentationPageSheet;
    controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)handleFilterSelectionCanceled
{
    if (self.postFilterPopoverController) {
        [self popoverControllerDidDismissPopover:self.postFilterPopoverController];
    }
}


#pragma mark - UIPopover Delegate Methods

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.postFilterPopoverController.delegate = nil;
    self.postFilterPopoverController = nil;
}


#pragma mark - Search Controller Delegate Methods

- (void)presentSearchController:(WPSearchController *)searchController
{
    [WPAnalytics track:WPAnalyticsStatPostListSearchOpened withProperties:[self propertiesForAnalytics]];
    [self.navigationController setNavigationBarHidden:YES animated:YES]; // Remove this line when switching to UISearchController.
    self.searchWrapperViewHeightConstraint.constant = [self heightForSearchWrapperView];
    [UIView animateWithDuration:PostSearchBarAnimationDuration
                          delay:0.0
                        options:0
                     animations:^{
                         [self.view layoutIfNeeded];
                     } completion:^(BOOL finished) {
                         [self.searchController.searchBar becomeFirstResponder];
                     }];
}

- (void)willDismissSearchController:(WPSearchController *)searchController
{
    [self.searchController.searchBar resignFirstResponder];
    [self.navigationController setNavigationBarHidden:NO animated:YES]; // Remove this line when switching to UISearchController.
    self.searchWrapperViewHeightConstraint.constant = 0;
    [UIView animateWithDuration:PostSearchBarAnimationDuration animations:^{
        [self.view layoutIfNeeded];
    }];

    self.searchController.searchBar.text = nil;
    [self updateAndPerformFetchRequestRefreshingCachedRowHeights];
}

- (void)updateSearchResultsForSearchController:(WPSearchController *)searchController
{
    [self updateAndPerformFetchRequestRefreshingCachedRowHeights];
}

@end
