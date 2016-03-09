#import "MenuItemSourcePostView.h"
#import "PostService.h"
#import "Post.h"

@interface MenuItemSourcePostAbstractView () <MenuItemSourcePostAbstractViewSubclass>
@end

@interface MenuItemSourcePostView ()
@property (nonatomic, strong) NSDate *oldestSyncedPostDate;
@end

@implementation MenuItemSourcePostView

- (NSString *)sourceItemType
{
    return MenuItemTypePost;
}

- (NSFetchRequest *)fetchRequest
{
    NSFetchRequest *fetchRequest = [super fetchRequest];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date_created_gmt" ascending:NO];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    return fetchRequest;
}

- (Class)entityClass
{
    return [Post class];
}

- (NSString *)postServiceType
{
    return PostServiceTypePost;
}

@end
