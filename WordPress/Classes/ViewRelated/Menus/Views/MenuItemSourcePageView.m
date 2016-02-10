#import "MenuItemSourcePageView.h"
#import "PostService.h"
#import "Page.h"

@interface MenuItemSourcePageView ()

@property (nonatomic, strong) PostService *pageSearchService;
@property (nonatomic, assign) BOOL additionalPagesAvailableForSync;

@end

@implementation MenuItemSourcePageView

- (id)init
{
    self = [super init];
    if(self) {
        
        [self insertSearchBarIfNeeded];
    }
    
    return self;
}

- (void)setItem:(MenuItem *)item
{
    [super setItem:item];
    [self syncPages];
}

- (NSFetchRequest *)fetchRequest
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([Page class]) inManagedObjectContext:[self managedObjectContext]];
    [fetchRequest setEntity:entity];
    fetchRequest.predicate = [self defaultFetchRequestPredicate];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"postTitle"
                                                                   ascending:YES
                                                                    selector:@selector(caseInsensitiveCompare:)];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    
    return fetchRequest;
}

- (NSPredicate *)defaultFetchRequestPredicate
{
    NSPredicate *basePredicate = [super defaultFetchRequestPredicate];
    NSPredicate *filteredPredicate = [NSPredicate predicateWithFormat:@"original == nil && status IN %@", @[PostStatusPublish, PostStatusPrivate]];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[basePredicate, filteredPredicate]];
    return predicate;
}

- (void)syncPages
{
    [self performResultsControllerFetchRequest];
    [self showLoadingSourcesIndicatorIfEmpty];
    void(^stopLoading)() = ^() {
        [self hideLoadingSourcesIndicator];
    };
    PostService *service = [[PostService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    [service syncPostsOfType:PostServiceTypePage
                withStatuses:@[PostStatusPublish, PostStatusPrivate]
                     forBlog:[self blog]
                     success:^(BOOL hasMore) {
                         stopLoading();
                     } failure:^(NSError *error) {
                         // TODO: show error message
                         stopLoading();
                     }];
}

- (void)configureSourceCell:(MenuItemSourceCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    Page *page = [self.resultsController objectAtIndexPath:indexPath];
    [cell setTitle:page.titleForDisplay];
}

#pragma mark - paging

- (void)scrollingWillDisplayEndOfTableView:(UITableView *)tableView
{
    if (!self.additionalPagesAvailableForSync || [self searchBarInputIsActive]) {
        return;
    }
    [self showLoadingSourcesIndicator];
    void(^stopLoading)() = ^() {
        [self hideLoadingSourcesIndicator];
    };
    PostService *service = [[PostService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    [service loadMorePostsOfType:PostServiceTypePage
                    withStatuses:@[PostStatusPrivate, PostStatusPublish]
                         forBlog:[self blog]
                         success:^(BOOL hasMore) {
                             
                             self.additionalPagesAvailableForSync = hasMore;
                             stopLoading();
                             
                         } failure:^(NSError *error) {
                             // TODO: show error message
                             stopLoading();
                         }];
}

#pragma mark - searching

- (void)searchBarInputChangeDetectedForLocalResultsUpdateWithText:(NSString *)searchText
{
    NSPredicate *defaultPredicate = [self defaultFetchRequestPredicate];
    NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"postTitle CONTAINS[cd] %@", searchText];
    NSPredicate *predicate = nil;
    
    if (searchText.length) {
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[defaultPredicate, searchPredicate]];
    } else {
        predicate = defaultPredicate;
    }
    
    if ([self.resultsController.fetchRequest.predicate isEqual:predicate]) {
        // same predicate, no update needed
        return;
    }
    
    DDLogDebug(@"MenuItemSourcePageView: Updating fetch request predicate");
    self.resultsController.fetchRequest.predicate = predicate;
    [self performResultsControllerFetchRequest];
    [self.tableView reloadData];
}

- (void)searchBarInputChangeDetectedForRemoteResultsUpdateWithText:(NSString *)searchText
{
    if (!searchText.length) {
        return;
    }
    if (!self.pageSearchService) {
        self.pageSearchService = [[PostService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    }
    [self showLoadingSourcesIndicator];
    void(^stopLoading)() = ^() {
        [self hideLoadingSourcesIndicator];
    };
    DDLogDebug(@"MenuItemSourcePageView: Searching posts via PostService");
    [self.pageSearchService searchPostsWithQuery:searchText
                                          ofType:PostServiceTypePage
                                    withStatuses:@[PostStatusPrivate, PostStatusPublish]
                                         forBlog:[self blog]
                                         success:^(NSArray *posts) {
                                             stopLoading();
                                         } failure:^(NSError *error) {
                                             stopLoading();
                                         }];
}

@end
