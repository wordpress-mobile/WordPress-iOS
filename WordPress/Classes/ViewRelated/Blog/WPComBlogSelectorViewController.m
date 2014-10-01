#import "WPComBlogSelectorViewController.h"

@implementation WPComBlogSelectorViewController

- (NSPredicate *)fetchRequestPredicate
{
    if ([self.tableView isEditing]) {
        return [NSPredicate predicateWithFormat:@"account.isWpcom = YES"];
    }

    return [NSPredicate predicateWithFormat:@"account.isWpcom = YES AND visible = YES"];
}

@end
