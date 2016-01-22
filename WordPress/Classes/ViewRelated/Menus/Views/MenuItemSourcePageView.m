#import "MenuItemSourcePageView.h"
#import "PostService.h"
#import "Page.h"

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
    NSPredicate *basePredicate = [NSPredicate predicateWithFormat:@"blog == %@ && original == nil", [self blog]];
    NSPredicate *filteredPredicate = [NSPredicate predicateWithFormat:@"status IN %@", @[PostStatusPublish, PostStatusPrivate]];
    
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[basePredicate, filteredPredicate]];
    fetchRequest.predicate = predicate;
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"postTitle"
                                                                   ascending:YES
                                                                    selector:@selector(caseInsensitiveCompare:)];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    
    return fetchRequest;
}

- (void)syncPages
{
    [self performResultsControllerFetchRequest];
    
    PostService *service = [[PostService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    [service syncPostsOfType:PostServiceTypePage withStatuses:@[PostStatusPublish, PostStatusPrivate] forBlog:[self blog] success:^(BOOL hasMore) {
        
        // updated
        
    } failure:^(NSError *error) {
        // TODO: show error message
    }];
}

- (void)configureSourceCellForDisplay:(MenuItemSourceCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    Page *page = [self.resultsController objectAtIndexPath:indexPath];
    [cell setTitle:page.titleForDisplay];
}


@end
