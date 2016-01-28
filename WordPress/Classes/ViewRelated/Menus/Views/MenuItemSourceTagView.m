#import "MenuItemSourceTagView.h"
#import "PostTagService.h"
#import "PostTag.h"
#import "Menu.h"
#import "MenuItem.h"
#import "Blog.h"

@interface MenuItemSourceTagView ()

@property (nonatomic, strong) PostTagService *tagSearchService;

@end

@implementation MenuItemSourceTagView

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

- (void)sourceTextBar:(MenuItemSourceTextBar *)textBar didUpdateWithText:(NSString *)text
{
    if (!self.tagSearchService) {
        self.tagSearchService = [[PostTagService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    }
    
    NSLog(@"Searching: %@", text);
    
    //    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    // setup the resultsController to reflect the search
    
    NSPredicate *defaultPredicate = [self defaultFetchRequestPredicate];
    NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"name BEGINSWITH[c] %@", text];
    NSPredicate *predicate = nil;
    
    if (text.length) {
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[defaultPredicate, searchPredicate]];
    } else {
        predicate = defaultPredicate;
    }
    
    self.resultsController.fetchRequest.predicate = predicate;
    [self performResultsControllerFetchRequest];
    [self.tableView reloadData];
    
    //    });
    
    if (!text.length) {
        // don't search remotely
        return;
    }
    
    [self.tagSearchService searchTagsWithName:text blog:[self blog] success:^(NSArray<PostTag *> *tags) {
        
        NSLog(@"searched with: %i", tags.count);
        
    } failure:^(NSError *error) {
        
        NSLog(@"failure");
    }];
}

@end
