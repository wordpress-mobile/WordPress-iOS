#import "MenuItemSourcePostAbstractView.h"
#import "PostService.h"
#import "AbstractPost.h"

@interface MenuItemSourcePostAbstractView () <MenuItemSourcePostAbstractViewSubclass>

@property (nonatomic, assign) NSUInteger numberOfSyncedPosts;
@property (nonatomic, assign) BOOL additionalPostsAvailableForSync;

@end

@implementation MenuItemSourcePostAbstractView

- (id)init
{
    self = [super init];
    if(self) {
        [self insertSearchBarIfNeeded];
    }
    
    return self;
}

- (void)setBlog:(Blog *)blog
{
    [super setBlog:blog];
    [self syncPosts];
}

- (NSFetchRequest *)fetchRequest
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([self entityClass]) inManagedObjectContext:[self managedObjectContext]];
    [fetchRequest setEntity:entity];
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
    [self performResultsControllerFetchRequest];
    [self showLoadingSourcesIndicatorIfEmpty];
    self.additionalPostsAvailableForSync = YES;
    
    PostService *service = [[PostService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    PostServiceSyncOptions *options = [self syncOptions];
    [service syncPostsOfType:[self postServiceType]
                 withOptions:options
                     forBlog:[self blog]
                     success:^(NSArray *posts) {
                         [self didFinishSyncingPosts:posts options:options];
                     } failure:^(NSError *error) {
                         [self didFinishSyncingPosts:nil options:options];
                     }];
}

- (void)configureSourceCell:(MenuItemSourceCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    AbstractPost *post = [self.resultsController objectAtIndexPath:indexPath];
    [cell setTitle:post.titleForDisplay];
}

#pragma mark - MenuItemSourcePostAbstractViewSubclass

- (Class)entityClass
{
    // Subclasses return the proper entity class
    return nil;
}

- (NSString *)postServiceType
{
    // Subclasses return the proper PostServiceType str
    return PostServiceTypeAny;
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
    if (!self.additionalPostsAvailableForSync || [self searchBarInputIsActive]) {
        return;
    }
    [self showLoadingSourcesIndicator];
    PostService *service = [[PostService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    PostServiceSyncOptions *options = [self syncOptions];
    options.offset = @(self.resultsController.fetchedObjects.count);
    [service syncPostsOfType:[self postServiceType]
                 withOptions:options
                     forBlog:[self blog]
                     success:^(NSArray *posts) {
                         [self didFinishSyncingPosts:posts options:options];
                     } failure:^(NSError *error) {
                         [self didFinishSyncingPosts:nil options:options];
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
    } else {
        predicate = defaultPredicate;
    }
    
    DDLogDebug(@"MenuItemSourcePostView: Updating fetch request predicate");
    self.resultsController.fetchRequest.predicate = predicate;
    [self performResultsControllerFetchRequest];
    [self.tableView reloadData];
}

- (void)searchBarInputChangeDetectedForRemoteResultsUpdateWithText:(NSString *)searchText
{
    if (!searchText.length || !self.additionalPostsAvailableForSync) {
        return;
    }
    [self showLoadingSourcesIndicator];
    void(^stopLoading)() = ^() {
        [self hideLoadingSourcesIndicator];
    };
    DDLogDebug(@"MenuItemSourcePostView: Searching posts via PostService");
    
    PostService *service = [[PostService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    PostServiceSyncOptions *options = [self syncOptions];
    options.search = searchText;
    [service syncPostsOfType:[self postServiceType]
                 withOptions:options
                     forBlog:[self blog]
                     success:^(NSArray *posts) {
                         stopLoading();
                     } failure:^(NSError *error) {
                         stopLoading();
                     }];
}

@end
