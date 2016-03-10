#import "MenuItemSourcePostView.h"
#import "PostService.h"
#import "Post.h"

@interface MenuItemSourcePostAbstractView () <MenuItemSourcePostAbstractViewSubclass>
@end

@interface MenuItemSourcePostView ()
@end

@implementation MenuItemSourcePostView

- (NSPredicate *)defaultFetchRequestPredicate
{
    NSPredicate *predicate = [super defaultFetchRequestPredicate];
    NSPredicate *postTypePredicate = [NSPredicate predicateWithFormat:@"postType = %@", self.sourceItemType];
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, postTypePredicate]];
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
    return self.sourceItemType;
}

@end
