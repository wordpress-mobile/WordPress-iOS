#import "MenuItemSourcePostView.h"
#import "PostService.h"
#import "Post.h"

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
    NSPredicate *basePredicate = [NSPredicate predicateWithFormat:@"blog == %@ && original == nil", [self blog]];
    NSPredicate *filteredPredicate = [NSPredicate predicateWithFormat:@"status IN %@", @[PostStatusPublish, PostStatusPrivate]];
    
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[basePredicate, filteredPredicate]];
    fetchRequest.predicate = predicate;
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date_created_gmt" ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    
    return fetchRequest;
}

- (void)syncPosts
{
    [self performResultsControllerFetchRequest];
    
    PostService *service = [[PostService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    [service syncPostsOfType:PostServiceTypePost withStatuses:@[PostStatusPublish, PostStatusPrivate] forBlog:[self blog] success:^(BOOL hasMore) {
        
        // updated
        
    } failure:^(NSError *error) {
        // TODO: show error message
    }];
}

- (void)configureSourceCell:(MenuItemSourceCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    Post *post = [self.resultsController objectAtIndexPath:indexPath];
    [cell setTitle:post.titleForDisplay];
}

@end
