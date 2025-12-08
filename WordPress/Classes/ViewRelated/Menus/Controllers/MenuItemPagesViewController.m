#import "MenuItemPagesViewController.h"
#import "WordPress-Swift.h"
#import "MenuPostServiceOptions.h"

@interface MenuItemAbstractPostsViewController () <MenuItemSourcePostAbstractViewSubclass>
@end

@interface MenuItemPagesViewController ()
@property (nonatomic, strong) NSString *oldestSyncedPageTitle;
@end

@implementation MenuItemPagesViewController

- (NSString *)sourceItemType
{
    return MenuItemType.page;
}

- (NSFetchRequest *)fetchRequest
{
    NSFetchRequest *fetchRequest = [super fetchRequest];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"postTitle"
                                                                   ascending:YES
                                                                    selector:@selector(caseInsensitiveCompare:)];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    return fetchRequest;
}

- (Class)entityClass
{
    return [Page class];
}

- (MenuPostServiceSyncOptions *)syncOptions
{
    MenuPostServiceSyncOptions *options = [super syncOptions];
    options.order = PostServiceResultsOrderAscending;
    options.orderBy = PostServiceResultsOrderingByTitle;
    return options;
}

@end
