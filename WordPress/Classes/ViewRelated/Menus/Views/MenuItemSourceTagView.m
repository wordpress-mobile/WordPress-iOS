#import "MenuItemSourceTagView.h"
#import "PostTagService.h"
#import "PostTag.h"
#import "Menu.h"
#import "MenuItem.h"
#import "Blog.h"

static NSUInteger const MenuItemSourceTagsSyncLimit = 100;

@interface MenuItemSourceTagView ()

@property (nonatomic, strong) NSTimer *searchRemoteServiceTimer;
@property (nonatomic, strong) PostTagService *searchTagService;
@property (nonatomic, assign) BOOL loadedAllAvailableTags;

@end

@implementation MenuItemSourceTagView

- (void)dealloc
{
    [self.searchRemoteServiceTimer invalidate];
}

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
    [self syncTags];
}

- (NSFetchRequest *)fetchRequest
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[PostTag entityName] inManagedObjectContext:[self managedObjectContext]];
    [fetchRequest setEntity:entity];
    // Specify criteria for filtering which objects to fetch
    [fetchRequest setPredicate:[self defaultFetchRequestPredicate]];
    // Specify how the fetched objects should be sorted
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name"
                                                                   ascending:YES
                                                                    selector:@selector(caseInsensitiveCompare:)];
    
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    [fetchRequest setFetchLimit:100];
    
    return fetchRequest;
}

- (void)syncTags
{
    PostTagService *tagService = [[PostTagService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    
    [self performResultsControllerFetchRequest];
    
    [self showLoadingSourcesIndicatorIfEmpty];
    void(^stopLoading)() = ^() {
        [self hideLoadingSourcesIndicator];
    };
    
    [tagService syncTagsForBlog:self.item.menu.blog success:^{
        
        stopLoading();
        
    } failure:^(NSError *error) {
        // TODO: show error message
        stopLoading();
    }];
}

- (void)configureSourceCell:(MenuItemSourceCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    PostTag *tag = [self.resultsController objectAtIndexPath:indexPath];
    [cell setTitle:tag.name];
}

- (void)scrollingWillDisplayEndOfTableView:(UITableView *)tableView
{
    if (self.loadedAllAvailableTags) {
        return;
    }
    
    // First try and increment the fetchLimit for local results.
    // This also allows the resultsController to load any additional tags synced afterwards.
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.resultsController.sections lastObject];
    NSUInteger countBefore = [sectionInfo numberOfObjects];

    self.resultsController.fetchRequest.fetchLimit = self.resultsController.fetchRequest.fetchLimit + MenuItemSourceTagsSyncLimit;
    [self performResultsControllerFetchRequest];
    
    sectionInfo = [self.resultsController.sections lastObject];
    NSUInteger countAfter = [sectionInfo numberOfObjects];
    if (countAfter > countBefore) {
        // Additional local results are available for display in the tableView.
        [tableView reloadData];
    }
    
    // Check if any additional tags are available locally based on the fetchLimit increase
    self.loadedAllAvailableTags = countAfter - countBefore < MenuItemSourceTagsSyncLimit;
    
    // Show the loading indicator
    [self showLoadingSourcesIndicator];
    void(^stopLoading)() = ^() {
        [self hideLoadingSourcesIndicator];
    };
    
    // Load any additional tags available remotely.
    // This will sync exsiting tags that may already be available locally, as well as loading additional tags.
    PostTagService *tagService = [[PostTagService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    [tagService syncTagsForBlog:[self blog]
                              number:@(MenuItemSourceTagsSyncLimit)
                              offset:@(countBefore)
                             success:^(NSArray<PostTag *> *tags) {
                                 
                                 // If the loaded tags count match the requested number, there is probably more tags available.
                                 self.loadedAllAvailableTags = tags.count < MenuItemSourceTagsSyncLimit;
                                 stopLoading();
                                 
                             } failure:^(NSError *error) {
                                 // TODO: Present error message if needed.
                                 stopLoading();
                             }];
}

#pragma mark - searching

- (void)searchBarInputChangeDetectedForLocalResultsUpdateWithText:(NSString *)searchText
{
    NSPredicate *defaultPredicate = [self defaultFetchRequestPredicate];
    NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"name BEGINSWITH[c] %@", searchText];
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
    
    DDLogDebug(@"MenuItemSourceTagView: Updating fetch request predicate");
    self.resultsController.fetchRequest.predicate = predicate;
    [self performResultsControllerFetchRequest];
    [self.tableView reloadData];
}

- (void)searchBarInputChangeDetectedForRemoteResultsUpdateWithText:(NSString *)searchText
{
    if (!searchText.length) {
        return;
    }
    
    [self showLoadingSourcesIndicator];
    void(^stopLoading)() = ^() {
        [self hideLoadingSourcesIndicator];
    };
    
    if (!self.searchTagService) {
        self.searchTagService = [[PostTagService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    }
    DDLogDebug(@"MenuItemSourceTagView: Searching tags PostTagService");
    [self.searchTagService searchTagsWithName:searchText
                                         blog:[self blog]
                                      success:^(NSArray<PostTag *> *tags) {
                                          stopLoading();
                                      } failure:^(NSError *error) {
                                          stopLoading();
                                      }];
}

@end
