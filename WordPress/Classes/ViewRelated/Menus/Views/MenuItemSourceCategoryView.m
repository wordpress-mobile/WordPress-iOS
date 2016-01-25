#import "MenuItemSourceCategoryView.h"
#import "PostCategory.h"
#import "PostCategoryService.h"
#import "Menu.h"
#import "MenuItem.h"
#import "Blog.h"

@interface MenuItemSourceCategoryView ()

@property (nonatomic, strong) NSMutableArray *orderedCategories;

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
    self.orderedCategories = [NSMutableArray array];
    [self performResultsControllerFetchRequest];
    
    PostCategoryService *categoryService = [[PostCategoryService alloc] initWithManagedObjectContext:[self managedObjectContext]];
    [categoryService syncCategoriesForBlog:[self blog] success:^{
       
        // updated
        
    } failure:^(NSError *error) {
        // TODO: show error message
    }];
}

- (void)configureSourceCell:(MenuItemSourceCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    PostCategory *category = [self.resultsController objectAtIndexPath:indexPath];
    [cell setTitle:category.categoryName];
}

@end
