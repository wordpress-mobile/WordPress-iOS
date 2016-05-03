#import "MenuItemSourceTagView.h"
#import "PostTagService.h"
#import "PostTag.h"
#import "Menu.h"
#import "MenuItem.h"
#import "Blog.h"

static NSUInteger const MenuItemSourceTagSyncLimit = 100;

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
    if (self) {
        [self insertSearchBarIfNeeded];
    }
    
    return self;
}

- (void)setBlog:(Blog *)blog
{
    [super setBlog:blog];
    [self syncTags];
}

- (NSString *)sourceItemType
{
    return MenuItemTypeTag;
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
    [fetchRequest setFetchLimit:MenuItemSourceTagSyncLimit];
    
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
    
    [tagService syncTagsForBlog:[self blog]
                         number:@(MenuItemSourceTagSyncLimit)
                         offset:@(0)
                        success:^(NSArray<PostTag *> *tags) {
                            stopLoading();
                        } failure:^(NSError *error) {
                            stopLoading();
                            [self showLoadingErrorMessageForResults];
                        }];
}

#pragma mark - TableView methods

- (void)configureSourceCell:(MenuItemSourceCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    PostTag *tag = [self.resultsController objectAtIndexPath:indexPath];
    if ([self itemTypeMatchesSourceItemType] && [self.item.contentID integerValue] == [tag.tagID integerValue]) {
        cell.sourceSelected = YES;
    } else {
        cell.sourceSelected = NO;
    }
    [cell setTitle:tag.name];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    
    PostTag *tag = [self.resultsController objectAtIndexPath:indexPath];
    [self setItemSourceWithContentID:tag.tagID name:tag.name];

    [self deselectVisibleSourceCellsIfNeeded];
    
    MenuItemSourceCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    selectedCell.sourceSelected = YES;
}

#pragma mark - 

- (void)scrollingWillDisplayEndOfTableView:(UITableView *)tableView
{
    if (self.loadedAllAvailableTags || [self searchBarInputIsActive]) {
        return;
    }
    
    // Check how many tags are currently loaded
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.resultsController.sections lastObject];
    NSUInteger initialCount = [sectionInfo numberOfObjects];
    if (initialCount < MenuItemSourceTagSyncLimit) {
        // Additional tags not available, not limit or remote paging needed.
        return;
    }
    
    // First try and increment the fetchLimit for local results.
    // This also allows the resultsController to load any additional tags synced afterwards.
    self.resultsController.fetchRequest.fetchLimit = self.resultsController.fetchRequest.fetchLimit + MenuItemSourceTagSyncLimit;
    [self performResultsControllerFetchRequest];
    
    sectionInfo = [self.resultsController.sections lastObject];
    NSUInteger countWithLimitIncrease = [sectionInfo numberOfObjects];
    if (countWithLimitIncrease > initialCount) {
        // Additional local results are available for display in the tableView.
        [tableView reloadData];
    }
    
    // Check if any additional tags are available locally based on the fetchLimit increase
    self.loadedAllAvailableTags = countWithLimitIncrease - initialCount < MenuItemSourceTagSyncLimit;
    
    // Show the loading indicator
    [self showLoadingSourcesIndicator];
    void(^stopLoading)() = ^() {
        [self hideLoadingSourcesIndicator];
    };
    
    // Load any additional tags available remotely.
    // This will sync exsiting tags that may already be available locally, as well as loading additional tags.
    PostTagService *tagService = [[PostTagService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    [tagService syncTagsForBlog:[self blog]
                              number:@(MenuItemSourceTagSyncLimit)
                              offset:@(initialCount)
                             success:^(NSArray<PostTag *> *tags) {
                                 
                                 // If the loaded tags count match the requested number, there is probably more tags available.
                                 self.loadedAllAvailableTags = tags.count < MenuItemSourceTagSyncLimit;
                                 stopLoading();
                                 
                             } failure:^(NSError *error) {
                                 stopLoading();
                                 [self showLoadingErrorMessageForResults];
                             }];
}

#pragma mark - searching

- (void)searchBarInputChangeDetectedForLocalResultsUpdateWithText:(NSString *)searchText
{
    NSPredicate *defaultPredicate = [self defaultFetchRequestPredicate];
    NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"name BEGINSWITH[c] %@", searchText];
    NSPredicate *predicate = nil;
    
    if (searchText.length) {
        self.defersFooterViewMessageUpdates = YES;
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[defaultPredicate, searchPredicate]];
    } else {
        self.defersFooterViewMessageUpdates = NO;
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
        self.defersFooterViewMessageUpdates = NO;
        return;
    }
    
    self.defersFooterViewMessageUpdates = NO;
    
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
                                          [self showLoadingErrorMessageForResults];
                                      }];
}

@end
