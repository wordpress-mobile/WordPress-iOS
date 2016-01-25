#import "MenuItemSourceCategoryView.h"
#import "PostCategory.h"
#import "PostCategoryService.h"
#import "Menu.h"
#import "MenuItem.h"
#import "Blog.h"
#import "WPCategoryTree.h"

@interface MenuItemSourceCategoryView ()

@property (nonatomic, strong) NSArray *displayCategories;
@property (nonatomic, strong) NSMutableDictionary *categoryIndentationDict;

@end

@implementation MenuItemSourceCategoryView

- (id)init
{
    self = [super init];
    if(self) {
        
    }
    
    return self;
}

- (void)setItem:(MenuItem *)item
{
    [super setItem:item];
    
    [self syncCategories];
}

- (NSFetchRequest *)fetchRequest
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[PostCategory entityName] inManagedObjectContext:[self managedObjectContext]];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"blog == %@", [self blog]];
    [fetchRequest setPredicate:predicate];
    
    NSSortDescriptor *sortNameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"categoryName"
                                                                       ascending:YES
                                                                        selector:@selector(caseInsensitiveCompare:)];
    
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortNameDescriptor, nil]];
    
    return fetchRequest;
}

- (void)syncCategories
{
    self.displayCategories = [NSMutableArray array];
    [self performResultsControllerFetchRequest];
    
    PostCategoryService *categoryService = [[PostCategoryService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    [categoryService syncCategoriesForBlog:[self blog] success:^{
       
        // updated, do nothing
        
    } failure:^(NSError *error) {
        // TODO: show error message
    }];
}

- (void)configureSourceCell:(MenuItemSourceCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    PostCategory *category = [self.displayCategories objectAtIndex:indexPath.row];
    [cell setTitle:category.categoryName];
    
    NSInteger indentationLevel = [[self.categoryIndentationDict objectForKey:[category.categoryID stringValue]] integerValue];
    [cell setSourceHierarchyIndentation:indentationLevel];
}

- (void)updateDisplayCategories
{
    // Get sorted categories by parent/child relationship
    self.categoryIndentationDict = [NSMutableDictionary dictionary];
    
    // Get sorted categories by parent/child relationship
    WPCategoryTree *tree = [[WPCategoryTree alloc] initWithParent:nil];
    [tree getChildrenFromObjects:self.resultsController.fetchedObjects];
    
    self.displayCategories = [tree getAllObjects];
    
    // Get the indentation level of each category.
    NSUInteger count = [self.displayCategories count];
    
    NSMutableDictionary *categoryDict = [NSMutableDictionary dictionary];
    for (NSInteger i = 0; i < count; i++) {
        PostCategory *category = [self.displayCategories objectAtIndex:i];
        [categoryDict setObject:category forKey:category.categoryID];
    }
    
    for (NSInteger i = 0; i < count; i++) {
        PostCategory *category = [self.displayCategories objectAtIndex:i];
        
        NSInteger indentationLevel = [self indentationLevelForCategory:category.parentID categoryCollection:categoryDict];
        
        [self.categoryIndentationDict setValue:[NSNumber numberWithInteger:indentationLevel]
                                        forKey:[category.categoryID stringValue]];
    }
    
    [self.tableView reloadData];
}

- (NSInteger)indentationLevelForCategory:(NSNumber *)parentID categoryCollection:(NSMutableDictionary *)categoryDict
{
    if ([parentID intValue] == 0) {
        return 0;
    }
    
    PostCategory *category = [categoryDict objectForKey:parentID];
    return ([self indentationLevelForCategory:category.parentID categoryCollection:categoryDict]) + 1;
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.displayCategories.count;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    // do nothing
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    // do nothing
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self updateDisplayCategories];
}

@end
