#import "MenuItemPagesViewController.h"
#ifdef KEYSTONE
#import "Keystone-Swift.h"
#else
#import "WordPress-Swift.h"
#endif
// For some reason, and only in some files, the modular import does not work.
// Just to be on the safe side, _all_ imports use the angle brackets style.
// We shall try to go back to the modular style on Keystone successfully builds for testing.
// @import WordPressData;
#import <WordPressData/WordPressData.h>

@interface MenuItemAbstractPostsViewController () <MenuItemSourcePostAbstractViewSubclass>
@end

@interface MenuItemPagesViewController ()
@property (nonatomic, strong) NSString *oldestSyncedPageTitle;
@end

@implementation MenuItemPagesViewController

- (NSString *)sourceItemType
{
    return MenuItemTypePage;
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

- (PostServiceSyncOptions *)syncOptions
{
    PostServiceSyncOptions *options = [super syncOptions];
    options.order = PostServiceResultsOrderAscending;
    options.orderBy = PostServiceResultsOrderingByTitle;
    return options;
}

@end
