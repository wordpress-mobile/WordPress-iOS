#import "MenuItemSourceTagView.h"
#import "PostTagService.h"
#import "PostTag.h"
#import "Menu.h"
#import "MenuItem.h"
#import "Blog.h"

@interface MenuItemSourceTagView ()

@property (nonatomic, strong) PostTagService *tagSearchService;
@property (nonatomic, strong) NSTimer *searchRemoteServiceTimer;

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
    
    return fetchRequest;
}

- (void)syncTags
{
    [self performResultsControllerFetchRequest];
    
    PostTagService *tagService = [[PostTagService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    [tagService syncTagsForBlog:self.item.menu.blog success:^{
        
        // updated
        
    } failure:^(NSError *error) {
        // TODO: show error message
    }];
}

- (void)configureSourceCell:(MenuItemSourceCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    PostTag *tag = [self.resultsController objectAtIndexPath:indexPath];
    [cell setTitle:tag.name];
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
    
    if (!self.tagSearchService) {
        self.tagSearchService = [[PostTagService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    }
    
    DDLogDebug(@"MenuItemSourceTagView: Searching tags PostTagService");
    [self.tagSearchService searchTagsWithName:searchText blog:[self blog] success:nil failure:nil];
}

@end
