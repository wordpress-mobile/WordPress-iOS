#import "AbstractPostListViewController.h"

#import "AbstractPostListViewControllerSubclass.h"
#import "AbstractPost.h"
#import "SiteSettingsViewController.h"
#import "PostPreviewViewController.h"
#import "SettingsSelectionViewController.h"
#import "UIView+Subviews.h"
#import "WordPressAppDelegate.h"
#import "WPAppAnalytics.h"
#import "WPSearchControllerConfigurator.h"
#import <WordPressApi/WordPressApi.h>

const NSTimeInterval PostsControllerRefreshInterval = 300; // 5 minutes
const NSInteger HTTPErrorCodeForbidden = 403;
const NSInteger PostsFetchRequestBatchSize = 10;
const NSInteger PostsLoadMoreThreshold = 4;
const CGSize PreferredFiltersPopoverContentSize = {320.0, 220.0};

const CGFloat DefaultHeightForFooterView = 44.0;

@interface AbstractPostListViewController()
@property (nonatomic) BOOL needsRefreshCachedCellHeightsBeforeLayout;
@end

@implementation AbstractPostListViewController

#pragma mark - Lifecycle Methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.recentlyTrashedPostObjectIDs = [NSMutableArray array];
    self.tableView = self.postListViewController.tableView;
    self.refreshControl = self.postListViewController.refreshControl;
    [self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];

    [self configureFilters];
    [self configureCellsForLayout];
    [self configureTableView];
    [self configureFooterView];
    [self configureSyncHelper];
    [self configureNavbar];
    [self configureSearchController];
    [self configureAuthorFilter];
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.searchController.active = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        if (![UIDevice isPad] && (self.searchWrapperViewHeightConstraint.constant > 0)) {
            self.searchWrapperViewHeightConstraint.constant = [self heightForSearchWrapperView];
        }
    } completion:nil];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    CGFloat width = CGRectGetWidth(self.view.frame);
    [self.tableViewHandler refreshCachedRowHeightsForWidth:width];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    self.needsRefreshCachedCellHeightsBeforeLayout = YES;
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    if (self.needsRefreshCachedCellHeightsBeforeLayout) {
        self.needsRefreshCachedCellHeightsBeforeLayout = NO;

        CGFloat width = CGRectGetWidth(self.view.frame);
        [self.tableViewHandler refreshCachedRowHeightsForWidth:width];
        [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
    }
}


#pragma mark - Multitasking support

- (void)handleApplicationDidBecomeActive:(NSNotification *)notification
{
    self.needsRefreshCachedCellHeightsBeforeLayout = YES;
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
    // PostFilters are created as needed, see method 'availablePostListFilters'.
    self.allPostListFilters = [NSMutableDictionary dictionaryWithCapacity:2];
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
            self.animatedBox = [WPAnimatedBox newAnimatedBox];
        }
        return self.animatedBox;
    }
    return [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"illustration-posts"]];
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
    
    WPSearchControllerConfigurator *searchControllerConfigurator = [[WPSearchControllerConfigurator alloc] initWithSearchController:self.searchController withSearchWrapperView:self.searchWrapperView];
    [searchControllerConfigurator configureSearchControllerAndWrapperView];
    [self configureSearchBarPlaceholder];
    self.searchController.delegate = self;
    self.searchController.searchResultsUpdater = self;
}

- (void)configureSearchBarPlaceholder
{
    // Adjust color depending on where the search bar is being presented.
    UIColor *placeholderColor = [WPStyleGuide wordPressBlue];
    NSString *placeholderText = NSLocalizedString(@"Search", @"Placeholder text for the search bar on the post screen.");
    NSAttributedString *attrPlacholderText = [[NSAttributedString alloc] initWithString:placeholderText attributes:[WPStyleGuide defaultSearchBarTextAttributes:placeholderColor]];
    [[UITextField appearanceWhenContainedInInstancesOfClasses:@[ [UISearchBar class], [self class] ]] setAttributedPlaceholder:attrPlacholderText];
    [[UITextField appearanceWhenContainedInInstancesOfClasses:@[ [UISearchBar class], [self class] ]] setDefaultTextAttributes:[WPStyleGuide defaultSearchBarTextAttributes:[UIColor whiteColor]]];
}

- (void)configureSearchWrapper
{
    self.searchWrapperView.backgroundColor = [WPStyleGuide wordPressBlue];
}

- (NSDictionary *)propertiesForAnalytics
{
    NSMutableDictionary *properties = [NSMutableDictionary dictionaryWithCapacity:3];
    properties[@"type"] = [self postTypeToSync];
    properties[@"filter"] = self.currentPostListFilter.title;
    
    NSNumber *dotComID = self.blog.dotComID;
    if (dotComID) {
        properties[WPAppAnalyticsKeyBlogID] = dotComID;
    }
    
    return properties;
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

    NSDate *lastSynced = self.lastSyncDate;
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

- (void)updateFilter:(PostListFilter *)filter withSyncedPosts:(NSArray <AbstractPost *> *)posts syncOptions:(PostServiceSyncOptions *)options
{
    AbstractPost *oldestPost = [posts lastObject];
    // Reset the filter to only show the latest sync point.
    filter.oldestPostDate = oldestPost.dateCreated;
    filter.hasMore = posts.count >= options.number.unsignedIntegerValue;
    
    [self updateAndPerformFetchRequestRefreshingCachedRowHeights];
}

- (NSUInteger)numberOfPostsPerSync
{
    return PostServiceDefaultNumberToSync;
}

#pragma mark - Sync Helper Delegate Methods

- (NSString *)postTypeToSync
{
    // Subclasses should override.
    return PostServiceTypeAny;
}

- (NSDate *)lastSyncDate
{
    return self.blog.lastPostsSync;
}

- (void)syncHelper:(WPContentSyncHelper *)syncHelper syncContentWithUserInteraction:(BOOL)userInteraction success:(void (^)(BOOL))success failure:(void (^)(NSError *))failure
{
    if ([self.recentlyTrashedPostObjectIDs count]) {
        [self.recentlyTrashedPostObjectIDs removeAllObjects];
        [self updateAndPerformFetchRequestRefreshingCachedRowHeights];
    }
    PostListFilter *filter = [self currentPostListFilter];
    NSNumber *author = [self shouldShowOnlyMyPosts] ? self.blog.account.userID : nil;
    __weak __typeof(self) weakSelf = self;
    
    PostService *postService = [[PostService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    
    PostServiceSyncOptions *options = [[PostServiceSyncOptions alloc] init];
    options.statuses = filter.statuses;
    options.authorID = author;
    options.number = @([self numberOfPostsPerSync]);
    options.purgesLocalSync = YES;
    
    [postService syncPostsOfType:[self postTypeToSync]
                     withOptions:options
                         forBlog:self.blog
                         success:^(NSArray *posts) {
                             if  (success) {
                                 [weakSelf updateFilter:filter
                                        withSyncedPosts:posts
                                            syncOptions:options];
                                 success(filter.hasMore);
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
    NSNumber *author = [self shouldShowOnlyMyPosts] ? self.blog.account.userID : nil;
    __weak __typeof(self) weakSelf = self;

    PostService *postService = [[PostService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    
    PostServiceSyncOptions *options = [[PostServiceSyncOptions alloc] init];
    options.statuses = filter.statuses;
    options.authorID = author;
    options.number = @([self numberOfPostsPerSync]);
    options.offset = @([self.tableViewHandler.resultsController.fetchedObjects count]);
    
    [postService syncPostsOfType:[self postTypeToSync]
                     withOptions:options
                         forBlog:self.blog
                         success:^(NSArray *posts) {
                             if (success) {
                                 [weakSelf updateFilter:filter
                                        withSyncedPosts:posts
                                            syncOptions:options];
                                 success(filter.hasMore);
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
    SiteSettingsViewController *editSiteViewController = [[SiteSettingsViewController alloc] initWithBlog:self.blog];
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
    fetchRequest.fetchLimit = [self numberOfPostsPerSync];
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
    NSFetchRequest *fetchRequest = self.tableViewHandler.resultsController.fetchRequest;
    
    // Set the predicate based on filtering by the oldestPostDate and not searching.
    PostListFilter *filter = [self currentPostListFilter];
    if (filter.oldestPostDate && !self.isSearching) {
        // Filter posts by any posts newer than the filter's oldestPostDate.
        // Also include any posts that don't have a date set, such as local posts created without a connection.
        NSPredicate *datePredicate = [NSPredicate predicateWithFormat:@"(date_created_gmt = NULL) OR (date_created_gmt >= %@)", filter.oldestPostDate];
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, datePredicate]];
    }
    
    // Set up the fetchLimit based on filtering or searching
    if (filter.oldestPostDate || self.isSearching) {
        // If filtering by the oldestPostDate or searching, the fetchLimit should be disabled.
        fetchRequest.fetchLimit = 0;
    } else {
        // If not filtering by the oldestPostDate or searching, set the fetchLimit to the default number of posts.
        fetchRequest.fetchLimit = [self numberOfPostsPerSync];
    }
    
    [fetchRequest setPredicate:predicate];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
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

- (void)resetTableViewContentOffset
{
    // Reset the tableView contentOffset to the top before we make any dataSource changes.
    CGPoint tableOffset = self.tableView.contentOffset;
    tableOffset.y = -self.tableView.contentInset.top;
    self.tableView.contentOffset = tableOffset;
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
    // If searching, don't try and sync additional posts.
    if (self.isSearching) {
        return;
    }
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
    NSManagedObjectID *postObjectID = apost.objectID;

    [self.recentlyTrashedPostObjectIDs addObject:postObjectID];

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

                       [self.recentlyTrashedPostObjectIDs removeObject:postObjectID];
                       [self.tableViewHandler invalidateCachedRowHeightAtIndexPath:indexPath];
                       [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                   }];
}

- (void)restorePost:(AbstractPost *)apost
{
    [WPAnalytics track:WPAnalyticsStatPostListRestoreAction withProperties:[self propertiesForAnalytics]];
    // if the post was recently deleted, update the status helper and reload the cell to display a spinner
    NSManagedObjectID *postObjectID = apost.objectID;

    [self.recentlyTrashedPostObjectIDs removeObject:postObjectID];

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
                         [self.recentlyTrashedPostObjectIDs addObject:postObjectID];
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
    UINavigationBar *navBar = self.navigationController.navigationBar;
    CGFloat height = CGRectGetHeight(navBar.frame) + [UIApplication sharedApplication].statusBarFrame.size.height;
    return MAX(height, SearchWrapperViewMinHeight);
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

- (NSArray *)availablePostListFilters
{
    PostAuthorFilter currentAuthorFilter = [self currentPostAuthorFilter];
    NSString *authorFilterKey = [NSString stringWithFormat:@"filter_key_%@", [[NSNumber numberWithUnsignedInteger:currentAuthorFilter] stringValue]];

    if (![self.allPostListFilters objectForKey:authorFilterKey]) {
        [self.allPostListFilters setObject:[PostListFilter newPostListFilters] forKey:authorFilterKey];
    }
    
    return [self.allPostListFilters objectForKey:authorFilterKey];
}

- (PostListFilter *)currentPostListFilter
{
    return self.availablePostListFilters[[self currentFilterIndex]];
}

- (PostListFilter *)filterThatDisplaysPostsWithStatus:(NSString *)postStatus
{
    NSUInteger index = [self indexOfFilterThatDisplaysPostsWithStatus:postStatus];
    
    return self.availablePostListFilters[index];
}


- (NSUInteger)indexOfFilterThatDisplaysPostsWithStatus:(NSString *)postStatus
{
    __block NSUInteger index = 0;
    __block BOOL found = NO;
    
    [self.availablePostListFilters enumerateObjectsUsingBlock:^(PostListFilter* _Nonnull filter, NSUInteger idx, BOOL* _Nonnull stop) {
        if ([filter.statuses containsObject:postStatus]) {
            index = idx;
            found = YES;
            *stop = YES;
        }
    }];
    
    if (!found) {
        // The draft filter is the catch all by convention.
        index = [self indexForFilterWithType:PostListStatusFilterDraft];
    }
    
    return index;
}

- (NSInteger)indexForFilterWithType:(PostListStatusFilter)filterType
{
    NSInteger index = [self.availablePostListFilters indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
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
    if (!filter || [filter integerValue] >= [self.availablePostListFilters count]) {
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

    [self.recentlyTrashedPostObjectIDs removeAllObjects];
    [self updateFilterTitle];
    [self resetTableViewContentOffset];
    [self updateAndPerformFetchRequestRefreshingCachedRowHeights];
}

- (void)updateFilterTitle
{
    [self.filterButton setAttributedTitleForTitle:[self currentPostListFilter].title];
}

- (void)displayFilters
{
    NSArray *titles = [self.availablePostListFilters wp_map:^id(PostListFilter *filter) {
        return filter.title;
    }];
    NSDictionary *dict = @{
                           SettingsSelectionDefaultValueKey   : [self.availablePostListFilters firstObject],
                           SettingsSelectionTitleKey          : NSLocalizedString(@"Filters", @"Title of the list of post status filters."),
                           SettingsSelectionTitlesKey         : titles,
                           SettingsSelectionValuesKey         : self.availablePostListFilters,
                           SettingsSelectionCurrentValueKey   : [self currentPostListFilter]
                           };

    SettingsSelectionViewController *controller = [[SettingsSelectionViewController alloc] initWithStyle:UITableViewStylePlain andDictionary:dict];
    controller.onItemSelected = ^(NSDictionary *selectedValue) {
        [self setCurrentFilterIndex:[self.availablePostListFilters indexOfObject:selectedValue]];
        [self dismissViewControllerAnimated:YES completion:nil];
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

    controller.modalPresentationStyle = UIModalPresentationPopover;
    [self presentViewController:controller animated:YES completion:nil];

    UIPopoverPresentationController *presentationController = controller.popoverPresentationController;
    presentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    presentationController.sourceView = self.navigationController.view;
    presentationController.sourceRect = titleRect;
}

- (void)displayFilterModal:(UIViewController *)controller
{
    controller.modalPresentationStyle = UIModalPresentationPageSheet;
    controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:controller animated:YES completion:nil];
}


- (void)setFilterWithPostStatus:(NSString* __nonnull)status
{
    NSUInteger index = [self indexOfFilterThatDisplaysPostsWithStatus:status];
    
    [self setCurrentFilterIndex:index];
}


#pragma mark - Search Controller Delegate Methods

- (void)presentSearchController:(WPSearchController *)searchController
{
    [WPAnalytics track:WPAnalyticsStatPostListSearchOpened withProperties:[self propertiesForAnalytics]];
    [self.navigationController setNavigationBarHidden:YES animated:YES]; // Remove this line when switching to UISearchController.
    self.searchWrapperViewHeightConstraint.constant = [self heightForSearchWrapperView];
    [UIView animateWithDuration:SearchBarAnimationDuration
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
    [UIView animateWithDuration:SearchBarAnimationDuration animations:^{
        [self.view layoutIfNeeded];
    }];

    self.searchController.searchBar.text = nil;
    [self resetTableViewContentOffset];
    [self updateAndPerformFetchRequestRefreshingCachedRowHeights];
}

- (void)updateSearchResultsForSearchController:(WPSearchController *)searchController
{
    [self resetTableViewContentOffset];
    [self updateAndPerformFetchRequestRefreshingCachedRowHeights];
}

@end
