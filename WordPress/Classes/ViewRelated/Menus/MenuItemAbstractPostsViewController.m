#import "MenuItemAbstractPostsViewController.h"
#import "PostService.h"
#import "AbstractPost.h"
@import WordPressKit;

@interface MenuItemAbstractPostsViewController () <MenuItemSourcePostAbstractViewSubclass>

@property (nonatomic, assign) NSUInteger numberOfSyncedPosts;
@property (nonatomic, assign) BOOL isSyncing;
@property (nonatomic, assign) BOOL isSyncingAdditionalPosts;
@property (nonatomic, assign) BOOL additionalPostsAvailableForSync;

@end

@implementation MenuItemAbstractPostsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self insertSearchBarIfNeeded];
}

- (void)setBlog:(Blog *)blog
{
    [super setBlog:blog];
    [self syncPosts];
}

- (NSFetchRequest *)fetchRequest
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([self entityClass])];
    fetchRequest.predicate = [self defaultFetchRequestPredicate];
    fetchRequest.fetchLimit = PostServiceDefaultNumberToSync;
    return fetchRequest;
}

- (NSPredicate *)defaultFetchRequestPredicate
{
    NSPredicate *basePredicate = [super defaultFetchRequestPredicate];
    NSPredicate *filteredPredicate = [NSPredicate predicateWithFormat:@"original == nil && status IN %@", @[PostStatusPublish, PostStatusPrivate]];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[basePredicate, filteredPredicate]];
    return predicate;
}

- (void)syncPosts
{
    if (self.isSyncing) {
        return;
    }

    [self performResultsControllerFetchRequest];

    self.isSyncing = YES;
    [self showLoadingSourcesIndicatorIfEmpty];
    self.additionalPostsAvailableForSync = YES;

    PostService *service = [[PostService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    PostServiceSyncOptions *options = [self syncOptions];
    [service syncPostsOfType:[self sourceItemType]
                 withOptions:options
                     forBlog:[self blog]
                     success:^(NSArray *posts) {
                         [self didFinishSyncingPosts:posts options:options];
                     } failure:^(NSError *error) {
                         [self didFinishSyncingPosts:nil options:options];
                         [self showLoadingErrorMessageForResults];
                     }];
}

- (NSString *)titleForPost:(AbstractPost *)post
{
    NSString *postTitle = post.titleForDisplay;
    if (!postTitle.length) {
        postTitle = NSLocalizedString(@"(Untitled)", @"Menus title label text for a post that has no set title.");
    }
    return postTitle;
}

#pragma mark - TableView methods

- (void)configureSourceCell:(MenuItemSourceCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    AbstractPost *post = [self.resultsController objectAtIndexPath:indexPath];
    if ([self itemTypeMatchesSourceItemType] && post.postID.integerValue == [self.item.contentID integerValue]) {
        cell.sourceSelected = YES;
    } else {
        cell.sourceSelected = NO;
    }
    [cell setTitle:[self titleForPost:post]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];

    AbstractPost *post = [self.resultsController objectAtIndexPath:indexPath];

    [self setItemSourceWithContentID:post.postID name:[self titleForPost:post]];
    [self deselectVisibleSourceCellsIfNeeded];

    MenuItemSourceCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    selectedCell.sourceSelected = YES;
}

#pragma mark - MenuItemSourcePostAbstractViewSubclass

- (Class)entityClass
{
    AssertSubclassMethod();
    return nil;
}

- (PostServiceSyncOptions *)syncOptions
{
    PostServiceSyncOptions *options = [[PostServiceSyncOptions alloc] init];
    options.statuses = @[PostStatusPublish, PostStatusPrivate];
    options.number = @(PostServiceDefaultNumberToSync);
    return options;
}

- (void)didFinishSyncingPosts:(NSArray *)posts options:(PostServiceSyncOptions *)options
{
    self.isSyncing = NO;
    if (posts) {
        self.numberOfSyncedPosts = self.numberOfSyncedPosts + posts.count;
        self.additionalPostsAvailableForSync = posts.count >= options.number.unsignedIntegerValue;
        self.resultsController.fetchRequest.fetchLimit = self.numberOfSyncedPosts;
        [self performResultsControllerFetchRequest];
        [self.tableView reloadData];
    }
    [self hideLoadingSourcesIndicator];
}

#pragma mark - paging

- (void)scrollingWillDisplayEndOfTableView:(UITableView *)tableView
{
    if (self.isSyncingAdditionalPosts || !self.additionalPostsAvailableForSync || [self searchBarInputIsActive]) {
        return;
    }

    self.isSyncing = YES;
    self.isSyncingAdditionalPosts = YES;
    [self showLoadingSourcesIndicator];

    PostService *service = [[PostService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    PostServiceSyncOptions *options = [self syncOptions];
    options.offset = @(self.resultsController.fetchedObjects.count);
    [service syncPostsOfType:[self sourceItemType]
                 withOptions:options
                     forBlog:[self blog]
                     success:^(NSArray *posts) {
                         [self didFinishSyncingPosts:posts options:options];
                         self.isSyncingAdditionalPosts = NO;
                     } failure:^(NSError *error) {
                         [self didFinishSyncingPosts:nil options:options];
                         self.isSyncingAdditionalPosts = NO;
                         [self showLoadingErrorMessageForResults];
                     }];
}

#pragma mark - searching

- (void)searchBarInputChangeDetectedForLocalResultsUpdateWithText:(NSString *)searchText
{
    NSPredicate *defaultPredicate = [self defaultFetchRequestPredicate];
    NSPredicate *predicate = nil;

    if (searchText.length) {
        NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"postTitle CONTAINS[cd] %@", searchText];
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[defaultPredicate, searchPredicate]];
        if ([self.resultsController.fetchRequest.predicate isEqual:predicate]) {
            // same predicate, no update needed
            return;
        }
        if (self.additionalPostsAvailableForSync) {
            self.defersFooterViewMessageUpdates = YES;
        }
        DDLogDebug(@"MenuItemSourcePostView: Updating fetch request with search predicate matching: %@", searchText);
    } else {
        DDLogDebug(@"MenuItemSourcePostView: Updating fetch request with default predicate");
        predicate = defaultPredicate;
    }

    self.resultsController.fetchRequest.predicate = predicate;
    [self performResultsControllerFetchRequest];
    [self.tableView reloadData];
}

- (void)searchBarInputChangeDetectedForRemoteResultsUpdateWithText:(NSString *)searchText
{
    if (!searchText.length || !self.additionalPostsAvailableForSync) {
        self.defersFooterViewMessageUpdates = NO;
        return;
    }

    self.defersFooterViewMessageUpdates = NO;

    [self showLoadingSourcesIndicator];
    void(^stopLoading)(void) = ^() {
        [self hideLoadingSourcesIndicator];
    };

    DDLogDebug(@"MenuItemSourcePostView: Searching posts via PostService");
    PostService *service = [[PostService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    PostServiceSyncOptions *options = [self syncOptions];
    options.search = searchText;
    [service syncPostsOfType:[self sourceItemType]
                 withOptions:options
                     forBlog:[self blog]
                     success:^(NSArray *posts) {
                         stopLoading();
                     } failure:^(NSError *error) {
                         stopLoading();
                         [self showLoadingErrorMessageForResults];
                     }];
}

@end
