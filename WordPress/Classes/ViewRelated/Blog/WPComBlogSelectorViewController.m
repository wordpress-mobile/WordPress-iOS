#import "WPComBlogSelectorViewController.h"

@implementation WPComBlogSelectorViewController

- (NSPredicate *)fetchRequestPredicate
{
    NSString *predicateString = @"account != NULL AND isHostedAtWPcom = YES";
    if ([self.tableView isEditing]) {
        predicateString = [NSString stringWithFormat:@"%@ AND visible = YES", predicateString];
    }

    return [NSPredicate predicateWithFormat:predicateString];
}

@end
