#import "MenuItemSourceCategoryView.h"
#import "PostCategory.h"
#import "PostCategoryService.h"
#import "Menu.h"
#import "MenuItem.h"
#import "Blog.h"

@interface MenuItemSourceCategoryView ()

@property (nonatomic, strong) NSMutableArray *categories;

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
    
    [self loadCategories];
}

- (void)loadCategories
{
    __weak Blog *blog = self.item.menu.blog;
    __weak MenuItemSourceCategoryView *weakSelf = self;
    PostCategoryService *categoryService = [[PostCategoryService alloc] initWithManagedObjectContext:self.item.managedObjectContext];
    [categoryService syncCategoriesForBlog:blog success:^{
       
        NSSet *categories = blog.categories;
        if (categories.count) {
            weakSelf.categories = [NSMutableArray arrayWithArray:[categories allObjects]];
        }
        [weakSelf.tableView reloadData];
        
    } failure:^(NSError *error) {
        
        
    }];
}

- (NSInteger)numberOfSourceTableSections
{
    return 1;
}

- (NSInteger)numberOfSourcesInTableSection:(NSInteger)section
{
    return self.categories.count;
}

- (void)willDisplaySourceCell:(MenuItemSourceCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    PostCategory *category = [self.categories objectAtIndex:indexPath.row];
    [cell setTitle:category.categoryName];
}

@end
