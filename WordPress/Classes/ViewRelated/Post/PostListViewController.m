#import "PostListViewController.h"

#import "AbstractPostListViewControllerSubclass.h"
#import "Post.h"
#import "PostCardTableViewCell.h"
#import "RestorePostTableViewCell.h"
#import "PrivateSiteURLProtocol.h"
#import "StatsPostDetailsTableViewController.h"
#import "WPStatsService.h"
#import "WPLegacyEditPostViewController.h"
#import "WPPostViewController.h"
#import "WPTableImageSource.h"
#import "WPToast.h"
#import <WordPress-iOS-Shared/UIImage+Util.h>

static NSString * const PostCardTextCellIdentifier = @"PostCardTextCellIdentifier";
static NSString * const PostCardImageCellIdentifier = @"PostCardImageCellIdentifier";
static NSString * const PostCardRestoreCellIdentifier = @"PostCardRestoreCellIdentifier";
static NSString * const PostCardTextCellNibName = @"PostCardTextCell";
static NSString * const PostCardImageCellNibName = @"PostCardImageCell";
static NSString * const PostCardRestoreCellNibName = @"RestorePostTableViewCell";
static NSString * const PostsViewControllerRestorationKey = @"PostsViewControllerRestorationKey";
static NSString * const StatsStoryboardName = @"SiteStats";
static NSString * const CurrentPostListStatusFilterKey = @"CurrentPostListStatusFilterKey";
static NSString * const CurrentPostAuthorFilterKey = @"CurrentPostAuthorFilterKey";

static const NSTimeInterval StatsCacheInterval = 300; // 5 minutes
static const CGFloat PostCardEstimatedRowHeight = 100.0;
static const CGFloat PostCardRestoreCellRowHeight = 54.0;
static const CGFloat PostListHeightForFooterView = 34.0;

@interface PostListViewController () <PostCardTableViewCellDelegate, UIViewControllerRestoration>

@property (nonatomic, strong) PostCardTableViewCell *textCellForLayout;
@property (nonatomic, strong) PostCardTableViewCell *imageCellForLayout;
@property (nonatomic, weak) IBOutlet UISegmentedControl *authorsFilter;

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
    self.title = NSLocalizedString(@"Posts", @"Tile of the screen showing the list of posts for a blog.");
}


#pragma mark - Configuration

- (CGFloat)heightForFooterView
{
    return PostListHeightForFooterView;
}

- (void)configureCellsForLayout
{
    self.textCellForLayout = (PostCardTableViewCell *)[[[NSBundle mainBundle] loadNibNamed:PostCardTextCellNibName owner:nil options:nil] firstObject];
    [self forceUpdateCellLayout:self.textCellForLayout];

    self.imageCellForLayout = (PostCardTableViewCell *)[[[NSBundle mainBundle] loadNibNamed:PostCardImageCellNibName owner:nil options:nil] firstObject];
    [self forceUpdateCellLayout:self.imageCellForLayout];
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

    UINib *postCardRestoreCellNib = [UINib nibWithNibName:PostCardRestoreCellNibName bundle:[NSBundle mainBundle]];
    [self.tableView registerNib:postCardRestoreCellNib forCellReuseIdentifier:PostCardRestoreCellIdentifier];
}

- (NSString *)noResultsTitleText
{
    if (self.syncHelper.isSyncing) {
        return NSLocalizedString(@"Fetching posts...", @"A brief prompt shown when the reader is empty, letting the user know the app is currently fetching new posts.");
    }
    PostListFilter *filter = [self currentPostListFilter];
    NSDictionary *titles = [self noResultsTitles];
    NSString *title = [titles stringForKey:@(filter.filterType)];
    return title;
}

- (NSDictionary *)noResultsTitles
{
    NSDictionary *titles;
    if ([self isSearching]) {
        titles = @{
                   @(PostListStatusFilterDraft):[NSString stringWithFormat:NSLocalizedString(@"No drafts match your search for %@", @"The '%@' is a placeholder for the search term."), [self currentSearchTerm]],
                   @(PostListStatusFilterScheduled):[NSString stringWithFormat:NSLocalizedString(@"No scheduled posts match your search for %@", @"The '%@' is a placeholder for the search term."), [self currentSearchTerm]],
                   @(PostListStatusFilterTrashed):[NSString stringWithFormat:NSLocalizedString(@"No trashed posts match your search for %@", @"The '%@' is a placeholder for the search term."), [self currentSearchTerm]],
                   @(PostListStatusFilterPublished):[NSString stringWithFormat:NSLocalizedString(@"No posts match your search for %@", @"The '%@' is a placeholder for the search term."), [self currentSearchTerm]],
                   };
    } else {
        titles = @{
                   @(PostListStatusFilterDraft):NSLocalizedString(@"You don't have any drafts.", @"Displayed when the user views drafts in the posts list and there are no posts"),
                   @(PostListStatusFilterScheduled):NSLocalizedString(@"You don't have any scheduled posts.", @"Displayed when the user views scheduled posts in the posts list and there are no posts"),
                   @(PostListStatusFilterTrashed):NSLocalizedString(@"You don't have any posts in your trash folder.", @"Displayed when the user views trashed in the posts list and there are no posts"),
                   @(PostListStatusFilterPublished):NSLocalizedString(@"You haven't published any posts yet.", @"Displayed when the user views published posts in the posts list and there are no posts"),
                   };
    }
    return titles;
}

- (NSString *)noResultsMessageText {
    if (self.syncHelper.isSyncing || [self isSearching]) {
        return [NSString string];
    }
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

- (NSString *)noResultsButtonText
{
    if (self.syncHelper.isSyncing || [self isSearching]) {
        return nil;
    }
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
    self.authorsFilterView.backgroundColor = [WPStyleGuide lightGrey];

    if (![self canFilterByAuthor]) {
        self.authorsFilterViewHeightConstraint.constant = 0.0;
        self.authorsFilter.hidden = YES;
    }

    if ([self currentPostAuthorFilter] == PostAuthorFilterMine) {
        self.authorsFilter.selectedSegmentIndex = 0;
    } else {
        self.authorsFilter.selectedSegmentIndex = 1;
    }
}


#pragma mark - Sync Methods

- (NSString *)postTypeToSync
{
    return PostServiceTypePost;
}


#pragma mark - Actions

- (IBAction)handleAuthorFilterChanged:(id)sender
{
    if (self.authorsFilter.selectedSegmentIndex == PostAuthorFilterMine) {
        [self setCurrentPostAuthorFilter:PostAuthorFilterMine];
    } else {
        [self setCurrentPostAuthorFilter:PostAuthorFilterEveryone];
    }
}


#pragma mark - TableView Handler Delegate Methods

- (NSString *)entityName
{
    return NSStringFromClass([Post class]);
}

- (NSPredicate *)predicateForFetchRequest
{
    NSMutableArray *predicates = [NSMutableArray array];

    NSPredicate *basePredicate = [NSPredicate predicateWithFormat:@"blog = %@ && original = nil", self.blog];
    [predicates addObject:basePredicate];

    NSString *searchText = [self currentSearchTerm];
    NSPredicate *filterPredicate = [self currentPostListFilter].predicateForFetchRequest;

    // If we have recently trashed posts, create an OR predicate to find posts matching the filter,
    // or posts that were recently deleted.
    if ([searchText length] == 0 && [self.recentlyTrashedPostIDs count] > 0) {
        NSPredicate *trashedPredicate = [NSPredicate predicateWithFormat:@"postID IN %@", self.recentlyTrashedPostIDs];
        filterPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[filterPredicate, trashedPredicate]];
    }
    [predicates addObject:filterPredicate];

    if ([self shouldShowOnlyMyPosts]) {
        // Brand new local drafts have an authorID of 0.
        NSPredicate *authorPredicate = [NSPredicate predicateWithFormat:@"authorID = %@ || authorID = 0", self.blog.account.userID];
        [predicates addObject:authorPredicate];
    }

    if ([searchText length] > 0) {
        NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"postTitle CONTAINS[cd] %@", searchText];
        [predicates addObject:searchPredicate];
    }

    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];

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
    } else {
        cell = self.imageCellForLayout;
    }
    [self configureCell:cell atIndexPath:indexPath];
    CGSize size = [cell sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    CGFloat height = ceil(size.height);
    return height;
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
    if ([self.recentlyTrashedPostIDs containsObject:post.postID] && [self currentPostListFilter].filterType != PostListStatusFilterTrashed) {
        identifier = PostCardRestoreCellIdentifier;
    } else if (![post.pathForDisplayImage length]) {
        identifier = PostCardTextCellIdentifier;
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

- (void)editPost:(AbstractPost *)apost
{
    [WPAnalytics track:WPAnalyticsStatPostListEditAction withProperties:[self propertiesForAnalytics]];
    if ([WPPostViewController isNewEditorEnabled]) {
        WPPostViewController *postViewController = [[WPPostViewController alloc] initWithPost:apost
                                                                                         mode:kWPPostViewControllerModeEdit];
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
    if (![blog supports:BlogFeatureStats]) {
        // Needs Jetpack.
        return;
    }

    [WPAnalytics track:WPAnalyticsStatPostListStatsAction withProperties:[self propertiesForAnalytics]];

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


#pragma mark - Filter related

- (PostAuthorFilter)currentPostAuthorFilter
{
    if (![self canFilterByAuthor]) {
        // No REST API, so we have to use XMLRPC and can't filter results by author.
        return PostAuthorFilterEveryone;
    }

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

    [WPAnalytics track:WPAnalyticsStatPostListAuthorFilterChanged withProperties:[self propertiesForAnalytics]];

    [[NSUserDefaults standardUserDefaults] setObject:@(filter) forKey:CurrentPostAuthorFilterKey];
    [NSUserDefaults resetStandardUserDefaults];

    [self.recentlyTrashedPostIDs removeAllObjects];
    [self updateAndPerformFetchRequestRefreshingCachedRowHeights];
    [self syncItemsWithUserInteraction:NO];
}

- (NSString *)keyForCurrentListStatusFilter
{
    return CurrentPostListStatusFilterKey;
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

@end
