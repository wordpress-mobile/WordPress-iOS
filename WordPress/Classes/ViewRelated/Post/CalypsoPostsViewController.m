#import "CalypsoPostsViewController.h"

#import <WordPress-iOS-Shared/WPStyleGuide.h>

#import "Blog.h"
#import "BlogService.h"
#import "ContextManager.h"
#import "EditSiteViewController.h"
#import "Post.h"
#import "PostService.h"
#import "PostCardTableViewCell.h"
#import "NavBarTitleDropdownButton.h"
#import "PostListViewController.h"
#import "PostPreviewViewController.h"
#import "PostSettingsSelectionViewController.h"
#import "StatsPostDetailsTableViewController.h"
#import "WPStatsService.h"
#import "UIView+Subviews.h"
#import "WordPressAppDelegate.h"
#import "WPLegacyEditPostViewController.h"
#import "WPNoResultsView+AnimatedBox.h"
#import "WPPostViewController.h"
#import "WPSearchController.h"
#import "WPTableImageSource.h"
#import "WPTableViewHandler.h"
#import <WordPress-iOS-Shared/UIImage+Util.h>
#import "WordPress-Swift.h"

static NSString * const PostCardTextCellIdentifier = @"PostCardTextCellIdentifier";
static NSString * const PostCardImageCellIdentifier = @"PostCardImageCellIdentifier";
static NSString * const PostCardTextCellNibName = @"PostCardTextCell";
static NSString * const PostCardImageCellNibName = @"PostCardImageCell";
static NSString * const PostsViewControllerRestorationKey = @"PostsViewControllerRestorationKey";
static NSString * const StatsStoryboardName = @"SiteStats";
static const NSTimeInterval StatsCacheInterval = 300; // 5 minutes
static const CGFloat PostCardEstimatedRowHeight = 100.0;
static const NSInteger PostsLoadMoreThreshold = 4;
static const NSTimeInterval PostsControllerRefreshTimeout = 300; // 5 minutes
static const NSInteger PostsFetchRequestBatchSize = 10;
static const CGFloat PostsSearchBarWidth = 200.0;
static const NSTimeInterval PostSearchBarAnimationDuration = 0.2; // seconds
static const CGSize PreferredFiltersPopoverContentSize = {320.0, 220.0};
static NSString * const CurrentPostListStatusFilterKey = @"CurrentPostListStatusFilterKey";

typedef NS_ENUM(NSUInteger, PostListStatusFilter) {
    PostListStatusFilterPublished,
    PostListStatusFilterDraft,
    PostListStatusFilterScheduled,
    PostListStatusFilterTrashed
};

@interface CalypsoPostsViewController () <WPTableViewHandlerDelegate,
                                            WPContentSyncHelperDelegate,
                                            UIViewControllerRestoration,
                                            WPNoResultsViewDelegate,
                                            PostCardTableViewCellDelegate,
                                            UIPopoverControllerDelegate,
                                            WPSearchControllerDelegate,
                                            WPSearchResultsUpdating>

@property (nonatomic, strong) PostListViewController *postListViewController;
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, weak) UIRefreshControl *refreshControl;
@property (nonatomic, strong) WPTableViewHandler *tableViewHandler;
@property (nonatomic, strong) WPContentSyncHelper *syncHelper;
@property (nonatomic, strong) PostCardTableViewCell *textCellForLayout;
@property (nonatomic, strong) PostCardTableViewCell *imageCellForLayout;
@property (nonatomic, strong) UIActivityIndicatorView *activityFooter;
@property (nonatomic, strong) WPNoResultsView *noResultsView;
@property (nonatomic, weak) IBOutlet NavBarTitleDropdownButton *filterButton;
@property (nonatomic, weak) IBOutlet UIView *rightBarButtonView;
@property (nonatomic, weak) IBOutlet UIButton *searchButton;
@property (nonatomic, weak) IBOutlet UIButton *addButton;
@property (nonatomic, weak) IBOutlet UIView *searchWrapperView; // Used on iPhone for presenting the search bar.
@property (nonatomic, weak) IBOutlet UIView *authorsFilterView; // Search lives here on iPad
@property (nonatomic, weak) IBOutlet UISegmentedControl *authorsFilter;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *authorsFilterViewHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *searchWrapperViewHeightConstraint;
@property (nonatomic, strong) WPSearchController *searchController; // Stand-in for UISearchController
@property (nonatomic, strong) UIPopoverController *postFilterPopoverController;

@end

@implementation CalypsoPostsViewController

#pragma mark - Lifecycle Methods

+ (instancetype)controllerWithBlog:(Blog *)blog
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Calypso" bundle:[NSBundle mainBundle]];
    CalypsoPostsViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"CalypsoPostsViewController"];
    controller.blog = blog;
    return controller;
}

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    NSString *blogID = [coder decodeObjectForKey:PostsViewControllerRestorationKey];
    if (!blogID) {
        return nil;
    }

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    NSManagedObjectID *objectID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:blogID]];
    if (!objectID) {
        return nil;
    }

    NSError *error = nil;
    Blog *restoredBlog = (Blog *)[context existingObjectWithID:objectID error:&error];
    if (error || !restoredBlog) {
        return nil;
    }

    return [self controllerWithBlog:restoredBlog];
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [coder encodeObject:[[self.blog.objectID URIRepresentation] absoluteString] forKey:PostsViewControllerRestorationKey];
    [super encodeRestorableStateWithCoder:coder];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    self.postListViewController = segue.destinationViewController;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Posts", @"Tile of the screen showing the list of posts for a blog.");
    self.tableView = self.postListViewController.tableView;
    self.refreshControl = self.postListViewController.refreshControl;
    [self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];

    [self configureCellsForLayout];
    [self configureTableView];
    [self configureTableViewHandler];
    [self configureSyncHelper];
    [self configureNavbar];
    [self configureAuthorFilter];
    [self configureSearchController];
    [self configureSearchBar];
    [self configureSearchWrapper];

    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
//TODO: If a new post was created, scroll to the top so it is visible.
// But how does this work if it is a draft, scheduled, etc. and the list has filters?
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

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.tableViewHandler refreshCachedRowHeightsForWidth:CGRectGetWidth(self.view.frame)];
}


#pragma mark - Configuration

- (void)configureNavbar
{
    // IMPORTANT: this code makes sure that the back button in WPPostViewController doesn't show
    // this VC's title.
    //
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:[NSString string] style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = backButton;

    UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.rightBarButtonView];
    [WPStyleGuide setRightBarButtonItemWithCorrectSpacing:rightBarButtonItem forNavigationItem:self.navigationItem];

    self.searchButton.hidden = [UIDevice isPad];

    self.navigationItem.titleView = self.filterButton;
    [self updateFilterTitle];
}

- (void)configureCellsForLayout
{
    self.textCellForLayout = (PostCardTableViewCell *)[[[NSBundle mainBundle] loadNibNamed:PostCardTextCellNibName owner:nil options:nil] firstObject];
    [self configureCellForLayout:self.textCellForLayout];

    self.imageCellForLayout = (PostCardTableViewCell *)[[[NSBundle mainBundle] loadNibNamed:PostCardImageCellNibName owner:nil options:nil] firstObject];
    [self configureCellForLayout:self.imageCellForLayout];
}

- (void)configureCellForLayout:(PostCardTableViewCell *)cellForLayout
{
    // Force a layout pass to ensure that constrants are configured for the
    // proper size class.
    [self.view addSubview:cellForLayout];
    [cellForLayout updateConstraintsIfNeeded];
    [cellForLayout layoutIfNeeded];
    [cellForLayout removeFromSuperview];
}

- (void)configureTableView
{
    self.tableView.accessibilityIdentifier = @"PostsTable";
    self.tableView.isAccessibilityElement = YES;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    // Register the cells
    UINib *postCardTextCellNib = [UINib nibWithNibName:PostCardTextCellNibName bundle:[NSBundle mainBundle]];
    [self.tableView registerNib:postCardTextCellNib forCellReuseIdentifier:PostCardTextCellIdentifier];

    UINib *postCardImageCellNib = [UINib nibWithNibName:PostCardImageCellIdentifier bundle:[NSBundle mainBundle]];
    [self.tableView registerNib:postCardImageCellNib forCellReuseIdentifier:PostCardImageCellIdentifier];
}

- (void)configureTableViewHandler
{
    self.tableViewHandler = [[WPTableViewHandler alloc] initWithTableView:self.tableView];
    self.tableViewHandler.cacheRowHeights = YES;
    self.tableViewHandler.delegate = self;
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
        return;
    }

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
    return NSLocalizedString(@"You haven't created any posts yet", @"Displayed when the user pulls up the posts view and they have no posts");
}

- (NSString *)noResultsMessageText {
    return NSLocalizedString(@"Would you like to create your first post?",  @"Displayed when the user pulls up the posts view and they have no posts");
}

- (UIView *)noResultsAccessoryView {
    return [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"penandink"]];
}

- (NSString *)noResultsButtonText
{
    return NSLocalizedString(@"Create post", @"Button title, encourages users to create their first post on their blog.");
}

- (void)configureAuthorFilter
{
    self.authorsFilterView.backgroundColor = [WPStyleGuide lightGrey];
    NSString *onlyMe = NSLocalizedString(@"Only Me", @"Label for the post author filter. This fliter shows posts only authored by the current user.");
    NSString *everyone = NSLocalizedString(@"Everyone", @"Label for the post author filter. This filter shows posts for all users on the blog.");
    [self.authorsFilter setTitle:onlyMe forSegmentAtIndex:0];
    [self.authorsFilter setTitle:everyone forSegmentAtIndex:1];
}

- (void)configureSearchController
{
    self.searchController = [[WPSearchController alloc] initWithSearchResultsController:nil];
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.hidesNavigationBarDuringPresentation = ![UIDevice isPad];
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

    if ([UIDevice isPad]) {
        [self configureSearchBarForFilterView];
    } else {
        [self configureSearchBarForSearchView];
    }
}

- (void)configureSearchBarForFilterView
{
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], [self class], nil] setDefaultTextAttributes:[WPStyleGuide defaultSearchBarTextAttributes:[WPStyleGuide darkGrey]]];
    [[UIButton appearanceWhenContainedIn:[UISearchBar class], [self class], nil] setTitleColor:[WPStyleGuide wordPressBlue] forState:UIControlStateNormal];
    UISearchBar *searchBar = self.searchController.searchBar;
    searchBar.barTintColor = [WPStyleGuide lightGrey];
    searchBar.showsCancelButton = NO;
    searchBar.barStyle = UIBarStyleDefault;

    [self.authorsFilterView addSubview:searchBar];

    NSDictionary *views = NSDictionaryOfVariableBindings(searchBar);
    NSDictionary *metrics = @{@"searchBarWidth":@(PostsSearchBarWidth)};
    [self.authorsFilterView addConstraint:[NSLayoutConstraint constraintWithItem:searchBar
                                                                       attribute:NSLayoutAttributeCenterY
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.authorsFilterView
                                                                       attribute:NSLayoutAttributeCenterY
                                                                      multiplier:1.0
                                                                        constant:0.0]];
    if (self.authorsFilter.hidden) {
        [self.authorsFilterView addConstraint:[NSLayoutConstraint constraintWithItem:searchBar
                                                                           attribute:NSLayoutAttributeCenterX
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self.authorsFilterView
                                                                           attribute:NSLayoutAttributeCenterX
                                                                          multiplier:1.0
                                                                            constant:0.0]];
        [self.authorsFilterView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[searchBar(searchBarWidth)]"
                                                                                       options:0
                                                                                       metrics:metrics
                                                                                         views:views]];
    } else {
        [self.authorsFilterView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[searchBar(searchBarWidth)]-|"
                                                                                       options:0
                                                                                       metrics:metrics
                                                                                         views:views]];
    }
}

- (void)configureSearchBarForSearchView
{
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], [self class], nil] setDefaultTextAttributes:[WPStyleGuide defaultSearchBarTextAttributes:[UIColor whiteColor]]];

    UISearchBar *searchBar = self.searchController.searchBar;
    searchBar.barTintColor = [WPStyleGuide wordPressBlue];
    searchBar.showsCancelButton = YES;
    searchBar.barStyle = UIBarStyleBlack;

    [self.searchWrapperView addSubview:searchBar];

    NSDictionary *views = NSDictionaryOfVariableBindings(searchBar);
    [self.searchWrapperView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[searchBar]|"
                                                                                   options:0
                                                                                   metrics:nil
                                                                                     views:views]];
    [self.searchWrapperView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[searchBar]|"
                                                                                   options:0
                                                                                   metrics:nil
                                                                                     views:views]];
}

- (void)configureSearchBarPlaceholder
{
    // Adjust color depending on where the search bar is being presented.
    UIColor *placeholderColor = [UIDevice isPad] ? [WPStyleGuide grey] : [WPStyleGuide wordPressBlue];
    NSString *placeholderText = NSLocalizedString(@"Search", @"Placeholder text for the search bar on the post screen.");
    NSAttributedString *attrPlacholderText = [[NSAttributedString alloc] initWithString:placeholderText attributes:[WPStyleGuide defaultSearchBarTextAttributes:placeholderColor]];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], [self class], nil] setAttributedPlaceholder:attrPlacholderText];
}

- (void)configureSearchWrapper
{
    self.searchWrapperView.backgroundColor = [WPStyleGuide wordPressBlue];
}

#pragma mark - Actions

- (IBAction)refresh:(id)sender
{
    [self syncItemsWithUserInteraction:YES];
}

- (IBAction)handleAddButtonTapped:(id)sender
{
    [self createPost];
}

- (IBAction)handleSearchButtonTapped:(id)sender
{
    [self toggleSearch];
}

- (IBAction)handleAuthorFilterChanged:(id)sender
{
    // TODO:
}

- (void)didTapNoResultsView:(WPNoResultsView *)noResultsView
{
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
        return;
    }

    NSDate *lastSynced = self.blog.lastPostsSync;
    if (lastSynced == nil || ABS([lastSynced timeIntervalSinceNow]) > PostsControllerRefreshTimeout) {
        // Update in the background
        [self syncItemsWithUserInteraction:NO];
    }
}

- (void)syncItemsWithUserInteraction:(BOOL)userInteraction
{
    [self configureNoResultsView];
    [self.syncHelper syncContentWithUserInteraction:userInteraction];
}

- (BOOL)hasMoreContent
{
    return [self.blog.hasOlderPosts boolValue];
}


#pragma mark - Sync Helper Delegate Methods

- (void)syncHelper:(WPContentSyncHelper *)syncHelper syncContentWithUserInteraction:(BOOL)userInteraction success:(void (^)(BOOL))success failure:(void (^)(NSError *))failure
{
    __weak __typeof(self) weakSelf = self;
    PostService *postService = [[PostService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    [postService syncPostsOfType:PostServiceTypePost forBlog:self.blog success:^{
        if  (success) {
            success([weakSelf hasMoreContent]);
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
    __weak __typeof(self) weakSelf = self;
    PostService *postService = [[PostService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    [postService loadMorePostsOfType:PostServiceTypePost forBlog:self.blog success:^{
        if (success) {
            success([weakSelf hasMoreContent]);
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
    [self.activityFooter stopAnimating];

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
        if (error.code == 403) {
            [self promptForPasswordWithMessage:nil];
            return;
        } else if (error.code == 425) {
            [self promptForPasswordWithMessage:[error localizedDescription]];
            return;
        }
    }
    [WPError showNetworkingAlertWithError:error title:NSLocalizedString(@"Unable to Sync", @"Title of error prompt shown when a sync the user initiated fails.")];
}

- (void)promptForPasswordWithMessage:(NSString *)message
{
    // TODO: Needs testing!!!
    if (message == nil) {
        message = NSLocalizedString(@"The username or password stored in the app may be out of date. Please re-enter your password in the settings and try again.", @"");
    }
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

- (NSManagedObjectContext *)managedObjectContext
{
    return [[ContextManager sharedInstance] mainContext];
}

- (NSFetchRequest *)fetchRequest
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Post class])];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(blog = %@) && (original = nil)", self.blog];
    NSSortDescriptor *sortDescriptorLocal = [NSSortDescriptor sortDescriptorWithKey:@"remoteStatusNumber" ascending:YES];
    NSSortDescriptor *sortDescriptorDate = [NSSortDescriptor sortDescriptorWithKey:@"date_created_gmt" ascending:NO];
    fetchRequest.sortDescriptors = @[sortDescriptorLocal, sortDescriptorDate];
    fetchRequest.fetchBatchSize = PostsFetchRequestBatchSize;
    return fetchRequest;
}


#pragma mark - Table View Handling

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return PostCardEstimatedRowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat width = CGRectGetWidth(self.tableView.bounds);
    return [self tableView:tableView heightForRowAtIndexPath:indexPath forWidth:width];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath forWidth:(CGFloat)width
{
    PostCardTableViewCell *cell;
    Post *post = (Post *)[self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    if ([post featuredImageURLForDisplay]) {
        cell = self.imageCellForLayout;
    } else {
        cell = self.textCellForLayout;
    }
    [self configureCell:cell atIndexPath:indexPath];
    CGSize size = [cell sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    CGFloat height = ceil(size.height);
    return height;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
// TODO: Preload images (maybe?)

    // Are we approaching the end of the table?
    if ((indexPath.section + 1 == self.tableView.numberOfSections) &&
        (indexPath.row + PostsLoadMoreThreshold >= [self.tableView numberOfRowsInSection:indexPath.section])) {

        // Only 3 rows till the end of table
        if (self.syncHelper.hasMoreContent) {
            [self.syncHelper syncMoreContent];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    AbstractPost *post = [self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    if (post.remoteStatus == AbstractPostRemoteStatusPushing) {
        // Don't allow editing while pushing changes
        return;
    }

    if ([post.status isEqualToString:@"trash"]) {
        // No editing posts that are trashed.
        return;
    }

    [self editPost:post];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PostCardTableViewCell *cell;
    Post *post = (Post *)[self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    if ([post featuredImageURLForDisplay]) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:PostCardImageCellIdentifier];
    } else {
        cell = [self.tableView dequeueReusableCellWithIdentifier:PostCardTextCellIdentifier];
    }
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    PostCardTableViewCell *postCell = (PostCardTableViewCell *)cell;
    postCell.delegate = self;
    Post *post = (Post *)[self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    [postCell configureCell:post];
}


#pragma mark - Instance Methods

#pragma mark - Post Actions

- (void)createPost
{
    // TODO: Flag we're adding a new post

    UINavigationController *navController;

    if ([WPPostViewController isNewEditorEnabled]) {
        WPPostViewController *postViewController = [[WPPostViewController alloc] initWithDraftForBlog:self.blog];
        navController = [[UINavigationController alloc] initWithRootViewController:postViewController];
        navController.restorationIdentifier = WPEditorNavigationRestorationID;
        navController.restorationClass = [WPPostViewController class];
    } else {
        WPLegacyEditPostViewController *editPostViewController = [[WPLegacyEditPostViewController alloc] initWithDraftForLastUsedBlog];
        navController = [[UINavigationController alloc] initWithRootViewController:editPostViewController];
        navController.restorationIdentifier = WPLegacyEditorNavigationRestorationID;
        navController.restorationClass = [WPLegacyEditPostViewController class];
    }

    [navController setToolbarHidden:NO]; // Fixes incorrect toolbar animation.
    navController.modalPresentationStyle = UIModalPresentationFullScreen;

    [self presentViewController:navController animated:YES completion:nil];

    [WPAnalytics track:WPAnalyticsStatEditorCreatedPost withProperties:@{ @"tap_source": @"posts_view" }];
}

- (void)editPost:(AbstractPost *)apost
{
    if ([WPPostViewController isNewEditorEnabled]) {
        WPPostViewController *postViewController = [[WPPostViewController alloc] initWithPost:apost
                                                                                         mode:kWPPostViewControllerModePreview];
        postViewController.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:postViewController animated:YES];
    } else {
        // In legacy mode, view means edit
        WPLegacyEditPostViewController *editPostViewController = [[WPLegacyEditPostViewController alloc] initWithPost:apost];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editPostViewController];
        [navController setToolbarHidden:NO]; // Fixes incorrect toolbar animation.
        navController.modalPresentationStyle = UIModalPresentationFullScreen;
        navController.restorationIdentifier = WPLegacyEditorNavigationRestorationID;
        navController.restorationClass = [WPLegacyEditPostViewController class];

        [self presentViewController:navController animated:YES completion:nil];
    }
}

- (void)viewPost:(AbstractPost *)apost
{
    PostPreviewViewController *controller = [[PostPreviewViewController alloc] initWithPost:apost shouldHideStatusBar:NO];
    controller.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)deletePost:(AbstractPost *)apost
{
    PostService *postService = [[PostService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    [postService deletePost:apost
                    success:nil
                    failure:^(NSError *error) {
                        if([error code] == 403) {
                            [self promptForPasswordWithMessage:nil];
                        } else {
                            [WPError showXMLRPCErrorAlert:error];
                        }
                        [self syncItemsWithUserInteraction:NO];
                    }];
}

- (void)publishPost:(AbstractPost *)apost
{
    apost.status = @"publish";
    apost.dateCreated = [NSDate date];
    PostService *postService = [[PostService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    [postService uploadPost:apost
                    success:nil
                    failure:^(NSError *error) {
                        if([error code] == 403) {
                            [self promptForPasswordWithMessage:nil];
                        } else {
                            [WPError showXMLRPCErrorAlert:error];
                        }
                        [self syncItemsWithUserInteraction:NO];
                    }];
}

- (void)restorePost:(AbstractPost *)apost
{
    PostService *postService = [[PostService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    [postService restorePost:apost
                    success:nil
                    failure:^(NSError *error) {
                        if([error code] == 403) {
                            [self promptForPasswordWithMessage:nil];
                        } else {
                            [WPError showXMLRPCErrorAlert:error];
                        }
                        [self syncItemsWithUserInteraction:NO];
                    }];
}

- (void)viewStatsForPost:(AbstractPost *)apost
{
    // Check the blog
    Blog *blog = apost.blog;
    if (!blog.isWPcom) {
        // Needs Jetpack.
        return;
    }

    // Push the Stats Post Details ViewController
    NSString *identifier = NSStringFromClass([StatsPostDetailsTableViewController class]);
    BlogService *service = [[BlogService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    UIStoryboard *statsStoryboard   = [UIStoryboard storyboardWithName:StatsStoryboardName bundle:nil];
    StatsPostDetailsTableViewController *controller = [statsStoryboard instantiateViewControllerWithIdentifier:identifier];
    NSAssert(controller, @"Couldn't instantiate StatsPostDetailsTableViewController");

    controller.postID = apost.postID;
    controller.postTitle = [apost titleForDisplay];
    controller.statsService = [[WPStatsService alloc] initWithSiteId:blog.blogID
                                                        siteTimeZone:[service timeZoneForBlog:blog]
                                                         oauth2Token:blog.authToken
                                          andCacheExpirationInterval:StatsCacheInterval];

    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - Search related

- (void)toggleSearch
{
    self.searchController.active = !self.searchController.active;
}

#pragma mark - Filter related

- (PostListStatusFilter)postListStatusFilter
{
    NSNumber *filter = [[NSUserDefaults standardUserDefaults] objectForKey:CurrentPostListStatusFilterKey];
    if (!filter) {
        // Published is default
        return PostListStatusFilterPublished;
    }
    return [filter integerValue];
}

- (void)setPostListStatusFilter:(PostListStatusFilter)newFilter
{
    PostListStatusFilter filter = [self postListStatusFilter];
    if (newFilter == filter) {
        return;
    }
    [[NSUserDefaults standardUserDefaults] setObject:@(newFilter) forKey:CurrentPostListStatusFilterKey];
    [NSUserDefaults resetStandardUserDefaults];
    // TODO: the filter changed, so update all the things.

    [self updateFilterTitle];
}

- (NSString *)titleForPostListStatusFilter:(PostListStatusFilter)filter
{
    NSString *title;
    switch (filter) {
        case PostListStatusFilterPublished:
            title = NSLocalizedString(@"Published", @"Title of the published filter. This filter shows a list of posts that the user has published.");
            break;
        case PostListStatusFilterDraft:
            title = NSLocalizedString(@"Draft", @"Title of the draft filter.  This filter shows a list of draft posts.");
            break;
        case PostListStatusFilterScheduled:
            title = NSLocalizedString(@"Scheduled", @"Title of the scheduled filter. This filter shows a list of posts that are scheduled to be published at a future date.");
            break;
        case PostListStatusFilterTrashed:
            title = NSLocalizedString(@"Trashed", @"Title of the trashed filter. This filter shows posts that have been moved to the trash bin.");
            break;
        default:
            break;
    }
    return title;
}

- (NSString *)titleForCurrentPostListStatusFilter
{
    PostListStatusFilter filter = [self postListStatusFilter];
    return [self titleForPostListStatusFilter:filter];
}

- (void)updateFilterTitle
{
    [self.filterButton setAttributedTitleForTitle:[self titleForCurrentPostListStatusFilter]];
}

- (void)displayFilters
{
    NSArray *filters = @[
                         @(PostListStatusFilterPublished),
                         @(PostListStatusFilterDraft),
                         @(PostListStatusFilterScheduled),
                         @(PostListStatusFilterTrashed),
                         ];
    NSMutableArray *titles = [NSMutableArray array];
    for (NSNumber *filter in filters) {
        [titles addObject:[self titleForPostListStatusFilter:[filter integerValue]]];
    }
    PostListStatusFilter currentFilter = [self postListStatusFilter];
    NSDictionary *dict = @{
                          @"DefaultValue"   : [filters firstObject],
                          @"Title"          : NSLocalizedString(@"Filters", @"Title of the list of post status filters."),
                          @"Titles"         : titles,
                          @"Values"         : filters,
                          @"CurrentValue"   : @(currentFilter)
                          };

    PostSettingsSelectionViewController *controller = [[PostSettingsSelectionViewController alloc] initWithStyle:UITableViewStylePlain andDictionary:dict];
    controller.onItemSelected = ^(NSObject *selectedValue) {
        // TODO: Handle the change
        if (self.postFilterPopoverController) {
            [self.postFilterPopoverController dismissPopoverAnimated:YES];
            self.postFilterPopoverController = nil;
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        NSNumber *selectedFilter = (NSNumber *)selectedValue;
        [self setPostListStatusFilter:[selectedFilter integerValue]];
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


#pragma mark - UIPopover Delegate Methods

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.postFilterPopoverController.delegate = nil;
    self.postFilterPopoverController = nil;
}


#pragma mark - Cell Delegate Methods

- (void)cell:(PostCardTableViewCell *)cell receivedEditActionForProvider:(id<WPPostContentViewProvider>)contentProvider
{
    AbstractPost *apost = (AbstractPost *)contentProvider;
    [self editPost:apost];
}

- (void)cell:(PostCardTableViewCell *)cell receivedViewActionForProvider:(id<WPPostContentViewProvider>)contentProvider
{
    AbstractPost *apost = (AbstractPost *)contentProvider;
    [self viewPost:apost];
}

- (void)cell:(PostCardTableViewCell *)cell receivedStatsActionForProvider:(id<WPPostContentViewProvider>)contentProvider
{
    AbstractPost *apost = (AbstractPost *)contentProvider;
    [self viewStatsForPost:apost];
}

- (void)cell:(PostCardTableViewCell *)cell receivedPublishActionForProvider:(id<WPPostContentViewProvider>)contentProvider
{
    AbstractPost *apost = (AbstractPost *)contentProvider;
    [self publishPost:apost];
}

- (void)cell:(PostCardTableViewCell *)cell receivedTrashActionForProvider:(id<WPPostContentViewProvider>)contentProvider
{
    AbstractPost *apost = (AbstractPost *)contentProvider;
    [self deletePost:apost];
}

- (void)cell:(PostCardTableViewCell *)cell receivedRestoreActionForProvider:(id<WPPostContentViewProvider>)contentProvider
{
    AbstractPost *apost = (AbstractPost *)contentProvider;
    [self restorePost:apost];
}


#pragma mark - Search Controller Delegate Methods

- (void)presentSearchController:(WPSearchController *)searchController
{
    if ([UIDevice isPad]) {
        [self.searchController.searchBar setShowsCancelButton:YES animated:YES];
        return;
    }
    [self.navigationController setNavigationBarHidden:YES animated:YES]; // Remove this line when switching to UISearchController.
    self.searchWrapperViewHeightConstraint.constant = 64.0;
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
    if ([UIDevice isPad]) {
        [self.searchController.searchBar setShowsCancelButton:NO animated:YES];
        return;
    }

    [self.searchController.searchBar resignFirstResponder];
    [self.navigationController setNavigationBarHidden:NO animated:YES]; // Remove this line when switching to UISearchController.
    self.searchWrapperViewHeightConstraint.constant = 0;
    [UIView animateWithDuration:PostSearchBarAnimationDuration animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)updateSearchResultsForSearchController:(WPSearchController *)searchController
{
    // TODO: filter results
}

@end
