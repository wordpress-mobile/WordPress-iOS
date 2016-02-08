#import "MenuItemSourcePostView.h"
#import "PostService.h"
#import "Post.h"

@interface MenuItemSourcePostView ()

@property (nonatomic, strong) PostService *postSearchService;

@end

@implementation MenuItemSourcePostView

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
    [self syncPosts];
}

- (NSFetchRequest *)fetchRequest
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([Post class]) inManagedObjectContext:[self managedObjectContext]];
    [fetchRequest setEntity:entity];
    fetchRequest.predicate = [self defaultFetchRequestPredicate];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date_created_gmt" ascending:NO];
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

- (void)syncPosts
{
    [self performResultsControllerFetchRequest];
    [self showLoadingSourcesIndicatorIfEmpty];
    void(^stopLoading)() = ^() {
        [self hideLoadingSourcesIndicator];
    };
    PostService *service = [[PostService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    [service syncPostsOfType:PostServiceTypePost
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
    Post *post = [self.resultsController objectAtIndexPath:indexPath];
    [cell setTitle:post.titleForDisplay];
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
    
    DDLogDebug(@"MenuItemSourcePostView: Updating fetch request predicate");
    self.resultsController.fetchRequest.predicate = predicate;
    [self performResultsControllerFetchRequest];
    [self.tableView reloadData];
}

- (void)searchBarInputChangeDetectedForRemoteResultsUpdateWithText:(NSString *)searchText
{
    if (!searchText.length) {
        return;
    }
    if (!self.postSearchService) {
        self.postSearchService = [[PostService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    }
    [self showLoadingSourcesIndicator];
    void(^stopLoading)() = ^() {
        [self hideLoadingSourcesIndicator];
    };
    DDLogDebug(@"MenuItemSourcePostView: Searching posts via PostService");
    [self.postSearchService searchPostsWithQuery:searchText
                                          ofType:PostServiceTypePost
                                    withStatuses:@[PostStatusPrivate, PostStatusPublish]
                                         forBlog:[self blog] success:^(NSArray *posts) {
                                             stopLoading();
                                         } failure:^(NSError *error) {
                                             stopLoading();
                                         }];
}

@end
