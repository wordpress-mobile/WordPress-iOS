#import "MenuItemCategoriesViewController.h"
#import "PostCategory.h"
#import "PostCategoryService.h"
#import "Menu.h"
#import "MenuItem.h"
#import "Blog.h"
#import "WordPress-Swift.h"

static NSUInteger const CategorySyncLimit = 1000;
static NSString * const CategorySortKey = @"categoryName";

@interface MenuItemCategoriesViewController ()

@property (nonatomic, strong) NSArray *displayCategories;
@property (nonatomic, strong) NSMutableDictionary *categoryIndentationDict;

@end

@implementation MenuItemCategoriesViewController

- (void)setBlog:(Blog *)blog
{
    [super setBlog:blog];
    [self syncCategories];
}

- (NSString *)sourceItemType
{
    return MenuItemTypeCategory;
}

- (NSFetchRequest *)fetchRequest
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[PostCategory entityName]];
    [fetchRequest setPredicate:[self defaultFetchRequestPredicate]];
    [fetchRequest setFetchLimit:CategorySyncLimit];

    NSSortDescriptor *sortNameDescriptor = [[NSSortDescriptor alloc] initWithKey:CategorySortKey
                                                                       ascending:YES
                                                                        selector:@selector(caseInsensitiveCompare:)];

    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortNameDescriptor, nil]];

    return fetchRequest;
}

- (void)syncCategories
{
    self.displayCategories = [NSMutableArray array];
    [self performResultsControllerFetchRequest];

    if (self.displayCategories.count == 0) {
        [self showLoadingSourcesIndicator];
    }
    void(^stopLoading)(void) = ^() {
        [self hideLoadingSourcesIndicator];
    };
    PostCategoryService *categoryService = [[PostCategoryService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    [categoryService syncCategoriesForBlog:[self blog]
                                    number:@(CategorySyncLimit)
                                    offset:@(0)
                                   success:^(NSArray<PostCategory *> *categories) {
                                       stopLoading();
                                   } failure:^(NSError *error) {
                                       stopLoading();
                                       [self showLoadingErrorMessageForResults];
                                   }];
}

#pragma mark - TableView methods

- (void)configureSourceCell:(MenuItemSourceCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    PostCategory *category = [self.displayCategories objectAtIndex:indexPath.row];

    if ([self itemTypeMatchesSourceItemType] && [self.item.contentID integerValue] == [category.categoryID integerValue]) {
        cell.sourceSelected = YES;
    } else {
        cell.sourceSelected = NO;
    }

    [cell setTitle:category.categoryName];

    NSInteger indentationLevel = [[self.categoryIndentationDict objectForKey:[category.categoryID stringValue]] integerValue];
    [cell setSourceHierarchyIndentation:indentationLevel];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];

    PostCategory *category = [self.displayCategories objectAtIndex:indexPath.row];
    [self setItemSourceWithContentID:category.categoryID name:category.categoryName];

    [self deselectVisibleSourceCellsIfNeeded];

    MenuItemSourceCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    selectedCell.sourceSelected = YES;
}

#pragma mark -

- (void)updateDisplayCategories
{
    // Get sorted categories by parent/child relationship
    self.categoryIndentationDict = [NSMutableDictionary dictionary];

    // Get sorted categories by parent/child relationship
    WPCategoryTree *tree = [[WPCategoryTree alloc] initWithParent:nil];
    [tree getChildrenFromObjects:self.resultsController.fetchedObjects];

    self.displayCategories = [tree getAllObjects];

    // Get the indentation level of each category.
    NSMutableDictionary *categoryDict = [NSMutableDictionary dictionary];
    for (PostCategory *category in self.displayCategories) {
        [categoryDict setObject:category forKey:category.categoryID];
    }
    for (PostCategory *category in self.displayCategories) {
        NSInteger indentationLevel = [self indentationLevelForCategory:category.parentID
                                                    categoryCollection:categoryDict];
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

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self updateDisplayCategories];
}

@end
