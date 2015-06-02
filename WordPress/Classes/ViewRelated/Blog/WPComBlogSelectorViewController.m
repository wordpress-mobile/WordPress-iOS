#import "WPComBlogSelectorViewController.h"

@implementation WPComBlogSelectorViewController

- (NSPredicate *)fetchRequestPredicate
{
    NSString *predicateString = @"account.isWpcom = YES AND isJetpack = NO";
    if ([self.tableView isEditing]) {
        predicateString = [NSString stringWithFormat:@"%@ AND visible = YES", predicateString];
    }

    return [NSPredicate predicateWithFormat:predicateString];
}

@end
