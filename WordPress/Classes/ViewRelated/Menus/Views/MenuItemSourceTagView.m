#import "MenuItemSourceTagView.h"
#import "PostTagService.h"
#import "PostTag.h"
#import "Menu.h"
#import "MenuItem.h"
#import "Blog.h"

@interface MenuItemSourceTagView ()

@property (nonatomic, strong) NSMutableArray <PostTag *> *tags;

@end

@implementation MenuItemSourceTagView

- (id)init
{
    self = [super init];
    if(self) {
        
        self.tags = [NSMutableArray array];
        [self insertSearchBarIfNeeded];
    }
    
    return self;
}

- (void)setItem:(MenuItem *)item
{
    [super setItem:item];
    
    [self loadTags];
}

- (void)loadTags
{
    PostTagService *tagService = [[PostTagService alloc] initWithManagedObjectContext:self.item.managedObjectContext];
    __weak Blog *blog = self.item.menu.blog;
    __weak MenuItemSourceTagView *weakSelf = self;
    [tagService syncTagsForBlog:self.item.menu.blog success:^{
        
        NSSet *tags = blog.tags;
        if (tags.count) {
            weakSelf.tags = [NSMutableArray arrayWithArray:[tags allObjects]];
        }
        [weakSelf.tableView reloadData];
        
    } failure:^(NSError *error) {
        
        // TODO: show error message
    }];
}

- (NSInteger)numberOfSourceTableSections
{
    return 1;
}

- (NSInteger)numberOfSourcesInTableSection:(NSInteger)section
{
    return self.tags.count;
}

- (void)willDisplaySourceCell:(MenuItemSourceCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    PostTag *tag = [self.tags objectAtIndex:indexPath.row];
    [cell setTitle:tag.name];
}

@end
