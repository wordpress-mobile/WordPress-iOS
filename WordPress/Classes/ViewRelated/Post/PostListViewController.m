#import "PostListViewController.h"

#import "Blog.h"
#import "BlogService.h"
#import "ContextManager.h"
#import "EditSiteViewController.h"
#import "NavBarTitleDropdownButton.h"
#import "Post.h"
#import "PostService.h"
#import "PostCardTableViewCell.h"
#import "RestorePostTableViewCell.h"
#import "PostListFilter.h"
#import "PostListFooterView.h"
#import "PostPreviewViewController.h"
#import "PostSettingsSelectionViewController.h"
#import "PrivateSiteURLProtocol.h"
#import "StatsPostDetailsTableViewController.h"
#import "WPStatsService.h"
#import "UIView+Subviews.h"
#import "WordPressAppDelegate.h"
#import "WPLegacyEditPostViewController.h"
#import "WPNoResultsView+AnimatedBox.h"
#import "WPPostViewController.h"
#import "WPSearchController.h"
#import "WPStyleGuide+Posts.h"
#import "WPTableImageSource.h"
#import "WPTableViewHandler.h"
#import "WPToast.h"
#import <WordPress-iOS-Shared/UIImage+Util.h>
#import <WordPress-iOS-Shared/WPStyleGuide.h>
#import "WordPress-Swift.h"

typedef NS_ENUM(NSUInteger, PostAuthorFilter) {
    PostAuthorFilterMine,
    PostAuthorFilterEveryone,
};

static NSString * const PostCardTextCellIdentifier = @"PostCardTextCellIdentifier";
static NSString * const PostCardImageCellIdentifier = @"PostCardImageCellIdentifier";
static NSString * const PostCardThumbCellIdentifier = @"PostCardThumbCellIdentifier";
static NSString * const PostCardRestoreCellIdentifier = @"PostCardRestoreCellIdentifier";
static NSString * const PostCardTextCellNibName = @"PostCardTextCell";
static NSString * const PostCardImageCellNibName = @"PostCardImageCell";
static NSString * const PostCardThumbCellNibName = @"PostCardThumbCell";
static NSString * const PostCardRestoreCellNibName = @"RestorePostTableViewCell";
static NSString * const PostsViewControllerRestorationKey = @"PostsViewControllerRestorationKey";
static NSString * const StatsStoryboardName = @"SiteStats";
static NSString * const CurrentPostListStatusFilterKey = @"CurrentPostListStatusFilterKey";
static NSString * const CurrentPostAuthorFilterKey = @"CurrentPostAuthorFilterKey";

static const NSTimeInterval StatsCacheInterval = 300; // 5 minutes
static const NSTimeInterval PostsControllerRefreshInterval = 300; // 5 minutes
static const NSTimeInterval PostSearchBarAnimationDuration = 0.2; // seconds

static const NSInteger PostsLoadMoreThreshold = 4;
static const NSInteger PostsFetchRequestBatchSize = 10;
static const CGFloat PostCardEstimatedRowHeight = 100.0;
static const CGFloat PostCardRestoreCellRowHeight = 54.0;
static const CGFloat PostsSearchBarWidth = 280.0;
static const CGFloat PostsSearchBariPadWidth = 210.0;
static const CGSize PreferredFiltersPopoverContentSize = {320.0, 220.0};
static const CGFloat SearchWrapperViewPortraitHeight = 64.0;
static const CGFloat SearchWrapperViewLandscapeHeight = 44.0;

@interface PostListViewController () <WPTableViewHandlerDelegate,
                                            WPContentSyncHelperDelegate,
                                            UIViewControllerRestoration,
                                            WPNoResultsViewDelegate,
                                            PostCardTableViewCellDelegate,
                                            UIPopoverControllerDelegate,
                                            WPSearchControllerDelegate,
                                            WPSearchResultsUpdating>

@property (nonatomic, strong) UITableViewController *postListViewController;
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, weak) UIRefreshControl *refreshControl;
@property (nonatomic, strong) WPTableViewHandler *tableViewHandler;
@property (nonatomic, strong) WPContentSyncHelper *syncHelper;
@property (nonatomic, strong) PostCardTableViewCell *textCellForLayout;
@property (nonatomic, strong) PostCardTableViewCell *imageCellForLayout;
@property (nonatomic, strong) PostCardTableViewCell *thumbCellForLayout;
@property (nonatomic, strong) WPNoResultsView *noResultsView;
@property (nonatomic, strong) PostListFooterView *postListFooterView;
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
@property (nonatomic, strong) NSArray *postListFilters;
@property (nonatomic, strong) NSMutableArray *recentlyTrashedPostIDs; // IDs of trashed posts. Cleared on refresh or when filter changes.

@end

@implementation PostListViewController

#pragma mark - Lifecycle Methods

+ (instancetype)controllerWithBlog:(Blog *)blog
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Posts" bundle:[NSBundle mainBundle]];
    PostListViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"PostListViewController"];
    controller.blog = blog;
    controller.restorationClass = [self class];
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

- (void)dealloc
{
    [PrivateSiteURLProtocol unregisterPrivateSiteURLProtocol];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [PrivateSiteURLProtocol registerPrivateSiteURLProtocol];
    }
    return self;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    self.postListViewController = segue.destinationViewController;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.recentlyTrashedPostIDs = [NSMutableArray array];

    self.title = NSLocalizedString(@"Posts", @"Tile of the screen showing the list of posts for a blog.");
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

    self.searchButton.hidden = [UIDevice isPad];

    self.navigationItem.titleView = self.filterButton;
    [self updateFilterTitle];
}

- (void)configureCellsForLayout
{
    self.textCellForLayout = (PostCardTableViewCell *)[[[NSBundle mainBundle] loadNibNamed:PostCardTextCellNibName owner:nil options:nil] firstObject];
    [self forceUpdateCellLayout:self.textCellForLayout];

    self.imageCellForLayout = (PostCardTableViewCell *)[[[NSBundle mainBundle] loadNibNamed:PostCardImageCellNibName owner:nil options:nil] firstObject];
    [self forceUpdateCellLayout:self.imageCellForLayout];

    self.thumbCellForLayout = (PostCardTableViewCell *)[[[NSBundle mainBundle] loadNibNamed:PostCardThumbCellNibName owner:nil options:nil] firstObject];
    [self forceUpdateCellLayout:self.thumbCellForLayout];
}

- (void)forceUpdateCellLayout:(PostCardTableViewCell *)cell
{
    // Force a layout pass to ensure that constrants are configured for the
    // proper size class.
    [self.view addSubview:cell];
    [cell updateConstraintsIfNeeded];
    [cell layoutIfNeeded];
    [cell removeFromSuperview];
}

- (void)configureTableView
{
    self.tableView.accessibilityIdentifier = @"PostsTable";
    self.tableView.isAccessibilityElement = YES;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    // Register the cells
    UINib *postCardTextCellNib = [UINib nibWithNibName:PostCardTextCellNibName bundle:[NSBundle mainBundle]];
    [self.tableView registerNib:postCardTextCellNib forCellReuseIdentifier:PostCardTextCellIdentifier];

    UINib *postCardImageCellNib = [UINib nibWithNibName:PostCardImageCellNibName bundle:[NSBundle mainBundle]];
    [self.tableView registerNib:postCardImageCellNib forCellReuseIdentifier:PostCardImageCellIdentifier];

    UINib *postCardThumbCellNib = [UINib nibWithNibName:PostCardThumbCellNibName bundle:[NSBundle mainBundle]];
    [self.tableView registerNib:postCardThumbCellNib forCellReuseIdentifier:PostCardThumbCellIdentifier];

    UINib *postCardRestoreCellNib = [UINib nibWithNibName:PostCardRestoreCellNibName bundle:[NSBundle mainBundle]];
    [self.tableView registerNib:postCardRestoreCellNib forCellReuseIdentifier:PostCardRestoreCellIdentifier];
}

- (void)configureFooterView
{
    self.postListFooterView = (PostListFooterView *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([PostListFooterView class]) owner:nil options:nil] firstObject];
    [self.postListFooterView showSpinner:NO];
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
    PostListFilter *filter = [self currentPostListFilter];
    NSString *title;
    switch (filter.filterType) {
        case PostListStatusFilterDraft:
            title = NSLocalizedString(@"You don't have any drafts.", @"Displayed when the user views drafts in the posts list and there are no posts");
            break;
        case PostListStatusFilterScheduled:
            title = NSLocalizedString(@"You don't have any scheduled posts.", @"Displayed when the user views scheduled posts in the posts list and there are no posts");
            break;
        case PostListStatusFilterTrashed:
            title = NSLocalizedString(@"You don't have any posts in your trash folder.", @"Displayed when the user views trashed in the posts list and there are no posts");
            break;
        default:
            title = NSLocalizedString(@"You haven't published any posts yet.", @"Displayed when the user views published posts in the posts list and there are no posts");
            break;
    }
    return title;
}

- (NSString *)noResultsMessageText {
    NSString *message;
    PostListFilter *filter = [self currentPostListFilter];
    switch (filter.filterType) {
        case PostListStatusFilterDraft:
            message = NSLocalizedString(@"Would you like to create one?", @"Displayed when the user views drafts in the posts list and there are no posts");
            break;
        case PostListStatusFilterScheduled:
            message = NSLocalizedString(@"Would you like to schedule a draft to publish?", @"Displayed when the user views scheduled posts in the posts list and there are no posts");
            break;
        case PostListStatusFilterTrashed:
            message = NSLocalizedString(@"Everything you write is solid gold.", @"Displayed when the user views trashed posts in the posts list and there are no posts");
            break;
        default:
            message = NSLocalizedString(@"Would you like to publish your first post?", @"Displayed when the user views published posts in the posts list and there are no posts");
            break;
    }
    return message;
}

- (UIView *)noResultsAccessoryView {
    return [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"penandink"]];
}

- (NSString *)noResultsButtonText
{
    NSString *title;
    PostListFilter *filter = [self currentPostListFilter];
    switch (filter.filterType) {
        case PostListStatusFilterScheduled:
            title = NSLocalizedString(@"Edit Drafts", @"Button title, encourages users to schedule a draft post to publish.");
            break;
        case PostListStatusFilterTrashed:
            title = [NSString string];
            break;
        default:
            title = NSLocalizedString(@"Start a Post", @"Button title, encourages users to create their first post on their blog.");
            break;
    }
    return title;
}

- (void)configureAuthorFilter
{
    NSString *onlyMe = NSLocalizedString(@"Only Me", @"Label for the post author filter. This fliter shows posts only authored by the current user.");
    NSString *everyone = NSLocalizedString(@"Everyone", @"Label for the post author filter. This filter shows posts for all users on the blog.");
    [WPStyleGuide applyPostAuthorFilterStyle:self.authorsFilter];
    [self.authorsFilter setTitle:onlyMe forSegmentAtIndex:0];
    [self.authorsFilter setTitle:everyone forSegmentAtIndex:1];
    self.authorsFilter.hidden = (!self.blog.isMultiAuthor || !self.blog.account.userID);

    self.authorsFilterView.backgroundColor = [WPStyleGuide lightGrey];
    if (![self.blog isMultiAuthor] && ![UIDevice isPad]) {
        // Collapse the view on iPhone if single author blog
        self.authorsFilterViewHeightConstraint.constant = 0.0;
    }

    if ([self currentPostAuthorFilter] == PostAuthorFilterMine) {
        self.authorsFilter.selectedSegmentIndex = 0;
    } else {
        self.authorsFilter.selectedSegmentIndex = 1;
    }
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
    [searchBar setImage:[UIImage imageNamed:@"icon-post-list-search"] forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
    if ([UIDevice isPad]) {
        [self configureSearchBarForFilterView];
    } else {
        [self configureSearchBarForSearchView];
    }
}

- (void)configureSearchBarForFilterView
{
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], [self class], nil] setDefaultTextAttributes:[WPStyleGuide defaultSearchBarTextAttributes:[WPStyleGuide postListSearchBarTextColor]]];
    [[UIButton appearanceWhenContainedIn:[UISearchBar class], [self class], nil] setTitleColor:[WPStyleGuide wordPressBlue] forState:UIControlStateNormal];
    UISearchBar *searchBar = self.searchController.searchBar;
    searchBar.barStyle = UIBarStyleDefault;
    searchBar.barTintColor = [WPStyleGuide lightGrey];
    searchBar.showsCancelButton = NO;

    [self.authorsFilterView insertSubview:searchBar atIndex:0];

    NSDictionary *views = NSDictionaryOfVariableBindings(searchBar);
    NSDictionary *metrics = @{
                              @"searchBarWidth":@(PostsSearchBarWidth),
                              @"searchBariPadWidth":@(PostsSearchBariPadWidth)
                              };
    [self.authorsFilterView addConstraint:[NSLayoutConstraint constraintWithItem:searchBar
                                                                       attribute:NSLayoutAttributeCenterY
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.authorsFilterView
                                                                       attribute:NSLayoutAttributeCenterY
                                                                      multiplier:1.0
                                                                        constant:0.0]];
    if (self.blog.isMultiAuthor) {
        [self.authorsFilterView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[searchBar(searchBariPadWidth)]-|"
                                                                                       options:0
                                                                                       metrics:metrics
                                                                                         views:views]];
    } else {
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
    }
}

- (void)configureSearchBarForSearchView
{
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], [self class], nil] setDefaultTextAttributes:[WPStyleGuide defaultSearchBarTextAttributes:[UIColor whiteColor]]];

    UISearchBar *searchBar = self.searchController.searchBar;
    searchBar.barStyle = UIBarStyleBlack;
    searchBar.barTintColor = [WPStyleGuide wordPressBlue];
    searchBar.showsCancelButton = YES;

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
    if (self.authorsFilter.selectedSegmentIndex == PostAuthorFilterMine) {
        [self setCurrentPostAuthorFilter:PostAuthorFilterMine];
    } else {
        [self setCurrentPostAuthorFilter:PostAuthorFilterEveryone];
    }
}

- (void)didTapNoResultsView:(WPNoResultsView *)noResultsView
{
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
    [self configureNoResultsView];
    [self.syncHelper syncContentWithUserInteraction:userInteraction];
}

- (void)setHasMore:(BOOL)hasMore forFilter:(PostListFilter *)filter
{
    filter.hasMore = hasMore;
}


#pragma mark - Sync Helper Delegate Methods

- (void)syncHelper:(WPContentSyncHelper *)syncHelper syncContentWithUserInteraction:(BOOL)userInteraction success:(void (^)(BOOL))success failure:(void (^)(NSError *))failure
{
    if ([self.recentlyTrashedPostIDs count]) {
        [self.recentlyTrashedPostIDs removeAllObjects];
        [self updateAndPerformFetchRequestClearingCachedRowHeights:YES];
    }

    PostListFilter *filter = [self currentPostListFilter];
    NSArray *postStatus = filter.statuses;
    __weak __typeof(self) weakSelf = self;
    PostService *postService = [[PostService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    [postService syncPostsOfType:PostServiceTypePost withStatuses:postStatus forBlog:self.blog success:^(BOOL hasMore){
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
    [self.postListFooterView showSpinner:YES];
    PostListFilter *filter = [self currentPostListFilter];
    NSArray *postStatus = filter.statuses;
    __weak __typeof(self) weakSelf = self;
    PostService *postService = [[PostService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    [postService loadMorePostsOfType:PostServiceTypePost withStatuses:postStatus forBlog:self.blog success:^(BOOL hasMore){
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
    fetchRequest.predicate = [self predicateForFetchRequest];
    NSSortDescriptor *sortDescriptorDate = [NSSortDescriptor sortDescriptorWithKey:@"date_created_gmt" ascending:NO];
    fetchRequest.sortDescriptors = @[sortDescriptorDate];
    fetchRequest.fetchBatchSize = PostsFetchRequestBatchSize;
    return fetchRequest;
}

- (void)updateAndPerformFetchRequestClearingCachedRowHeights:(BOOL)clearCachedRowHeights
{
    NSAssert([NSThread isMainThread], @"PostsViewController Error: NSFetchedResultsController accessed in BG");

    NSPredicate *predicate = [self predicateForFetchRequest];
    NSError *error = nil;
    [self.tableViewHandler.resultsController.fetchRequest setPredicate:predicate];
    [self.tableViewHandler.resultsController performFetch:&error];
    if (error) {
        DDLogError(@"Error fetching posts after updating the fetch request predicate: %@", error);
    }
    if (clearCachedRowHeights) {
        [self.tableViewHandler clearCachedRowHeights];
    }
    [self.tableView reloadData];
    [self configureNoResultsView];
}

- (NSPredicate *)predicateForFetchRequest
{
    NSMutableArray *predicates = [NSMutableArray array];

    NSPredicate *basePredicate = [NSPredicate predicateWithFormat:@"blog = %@ && original = nil", self.blog];
    [predicates addObject:basePredicate];

    NSPredicate *filterPredicate = [self currentPostListFilter].predicateForFetchRequest;
    [predicates addObject:filterPredicate];

    if (self.blog.isMultiAuthor && ![self shouldShowPostsForEveryone] && [self.blog.account.userID integerValue] > 0) {
        NSPredicate *authorPredicate = [NSPredicate predicateWithFormat:@"authorID = %@", self.blog.account.userID];
        [predicates addObject:authorPredicate];
    }

    NSString *searchText = self.searchController.searchBar.text;
    if ([searchText length] > 0) {
        NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"postTitle CONTAINS[cd] %@", searchText];
        [predicates addObject:searchPredicate];
    }

    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    if ([self.recentlyTrashedPostIDs count] > 0) {
        NSPredicate *trashedPredicate = [NSPredicate predicateWithFormat:@"postID IN %@", self.recentlyTrashedPostIDs];
        predicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[predicate, trashedPredicate]];
    }

    return predicate;
}


#pragma mark - Table View Handling

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Post *post = (Post *)[self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    if ([[self cellIdentifierForPost:post] isEqualToString:PostCardRestoreCellIdentifier]) {
        return PostCardRestoreCellRowHeight;
    }

    return PostCardEstimatedRowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Post *post = (Post *)[self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    if ([[self cellIdentifierForPost:post] isEqualToString:PostCardRestoreCellIdentifier]) {
        return PostCardRestoreCellRowHeight;
    }

    CGFloat width = CGRectGetWidth(self.tableView.bounds);
    return [self tableView:tableView heightForRowAtIndexPath:indexPath forWidth:width];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath forWidth:(CGFloat)width
{
    PostCardTableViewCell *cell;
    Post *post = (Post *)[self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    if (![post.pathForDisplayImage length]) {
        cell = self.textCellForLayout;
    } else if(post.post_thumbnail) {
        cell = self.thumbCellForLayout;
    } else {
        cell = self.imageCellForLayout;
    }
    [self configureCell:cell atIndexPath:indexPath];
    CGSize size = [cell sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    CGFloat height = ceil(size.height);
    return height;
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    AbstractPost *post = [self.tableViewHandler.resultsController objectAtIndexPath:indexPath];
    if (post.remoteStatus == AbstractPostRemoteStatusPushing) {
        // Don't allow editing while pushing changes
        return;
    }

    if ([post.status isEqualToString:PostStatusTrash]) {
        // No editing posts that are trashed.
        return;
    }

    [self editPost:post];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Post *post = (Post *)[self.tableViewHandler.resultsController objectAtIndexPath:indexPath];

    NSString *identifier = [self cellIdentifierForPost:post];
    PostCardTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    id<PostCardCell>postCell = (id<PostCardCell>)cell;
    postCell.delegate = self;
    Post *post = (Post *)[self.tableViewHandler.resultsController objectAtIndexPath:indexPath];

    [postCell configureCell:post];
}

- (NSString *)cellIdentifierForPost:(Post *)post
{
    NSString *identifier;
    if ([self.recentlyTrashedPostIDs containsObject:post.postID]) {
        identifier = PostCardRestoreCellIdentifier;
    } else if (![post.pathForDisplayImage length]) {
        identifier = PostCardTextCellIdentifier;
    } else if (post.post_thumbnail) {
        identifier = PostCardThumbCellIdentifier;
    } else {
        identifier = PostCardImageCellIdentifier;
    }
    return identifier;
}


#pragma mark - Instance Methods

#pragma mark - Post Actions

- (void)createPost
{
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

- (void)publishPost:(AbstractPost *)apost
{
    apost.status = PostStatusPublish;
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
    NSNumber *postID = apost.postID;
    [self.recentlyTrashedPostIDs addObject:postID];
    NSIndexPath *indexPath = [self.tableViewHandler.resultsController indexPathForObject:apost];
    [self.tableViewHandler invalidateCachedRowHeightAtIndexPath:indexPath];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];

    // Update the fetch request *before* making the service call.
    [self updateAndPerformFetchRequestClearingCachedRowHeights:YES];

    PostService *postService = [[PostService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    [postService trashPost:apost
                   success:nil
                    failure:^(NSError *error) {
                        if([error code] == 403) {
                            [self promptForPasswordWithMessage:nil];
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
                             [self promptForPasswordWithMessage:nil];
                         } else {
                             [WPError showXMLRPCErrorAlert:error];
                         }
                         [self.recentlyTrashedPostIDs addObject:postID];
                     }];
}

- (void)promptThatPostRestoredToFilter:(PostListFilter *)filter
{
    NSString *message = NSLocalizedString(@"Post Restored to Drafts", @"Prompts the user that a restored post was moved to the drafts list.");
    switch (filter.filterType) {
        case PostListStatusFilterPublished:
            message = NSLocalizedString(@"Post Restored to Published", @"Prompts the user that a restored post was moved to the published list.");
            break;
        case PostListStatusFilterScheduled:
            message = NSLocalizedString(@"Post Restored to Scheduled", @"Prompts the user that a restored post was moved to the scheduled list.");
            break;
        default:
            break;
    }
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", @"Title of an OK button. Pressing the button acknowledges and dismisses a prompt.")
                                              otherButtonTitles:nil, nil];
    [alertView show];
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
    NSString *path = [[NSBundle mainBundle] pathForResource:@"WordPressCom-Stats-iOS" ofType:@"bundle"];
    UIStoryboard *statsStoryboard   = [UIStoryboard storyboardWithName:StatsStoryboardName bundle:[NSBundle bundleWithPath:path]];
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

- (CGFloat)heightForSearchWrapperView
{
    return UIDeviceOrientationIsPortrait(self.interfaceOrientation) ? SearchWrapperViewPortraitHeight : SearchWrapperViewLandscapeHeight;
}

#pragma mark - Filter related

- (BOOL)shouldShowPostsForEveryone
{
    PostAuthorFilter filter = [self currentPostAuthorFilter];
    return filter == PostAuthorFilterEveryone;
}

- (PostAuthorFilter)currentPostAuthorFilter
{
    NSNumber *filter = [[NSUserDefaults standardUserDefaults] objectForKey:CurrentPostAuthorFilterKey];
    if (filter) {
        if (PostAuthorFilterEveryone == [filter integerValue]) {
            return PostAuthorFilterEveryone;
        }
    }
    return PostAuthorFilterMine;
}

- (void)setCurrentPostAuthorFilter:(PostAuthorFilter)filter
{
    if (filter == [self currentPostAuthorFilter]) {
        return;
    }
    [[NSUserDefaults standardUserDefaults] setObject:@(filter) forKey:CurrentPostAuthorFilterKey];
    [NSUserDefaults resetStandardUserDefaults];
    [self.recentlyTrashedPostIDs removeAllObjects];
    [self updateAndPerformFetchRequestClearingCachedRowHeights:YES];
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

- (NSInteger)currentFilterIndex
{
    NSNumber *filter = [[NSUserDefaults standardUserDefaults] objectForKey:CurrentPostListStatusFilterKey];
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
    [[NSUserDefaults standardUserDefaults] setObject:@(newIndex) forKey:CurrentPostListStatusFilterKey];
    [NSUserDefaults resetStandardUserDefaults];

    [self.recentlyTrashedPostIDs removeAllObjects];
    [self updateFilterTitle];
    [self updateAndPerformFetchRequestClearingCachedRowHeights:YES];
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
                          @"DefaultValue"   : [self.postListFilters firstObject],
                          @"Title"          : NSLocalizedString(@"Filters", @"Title of the list of post status filters."),
                          @"Titles"         : titles,
                          @"Values"         : self.postListFilters,
                          @"CurrentValue"   : [self currentPostListFilter]
                          };

    PostSettingsSelectionViewController *controller = [[PostSettingsSelectionViewController alloc] initWithStyle:UITableViewStylePlain andDictionary:dict];
    controller.onItemSelected = ^(NSObject *selectedValue) {
        if (self.postFilterPopoverController) {
            [self.postFilterPopoverController dismissPopoverAnimated:YES];
            self.postFilterPopoverController = nil;
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        [self setCurrentFilterIndex:[self.postListFilters indexOfObject:selectedValue]];
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

    self.searchController.searchBar.text = nil;
    [self updateAndPerformFetchRequestClearingCachedRowHeights:YES];
}

- (void)updateSearchResultsForSearchController:(WPSearchController *)searchController
{
    [self updateAndPerformFetchRequestClearingCachedRowHeights:YES];
}

@end
