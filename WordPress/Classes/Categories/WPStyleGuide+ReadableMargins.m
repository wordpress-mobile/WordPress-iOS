#import "WPStyleGuide+ReadableMargins.h"

@implementation WPStyleGuide (ReadableMargins)

+ (void)resetReadableMarginsForTableView:(UITableView *)tableView
{
    // By default, iOS 9 sets cellLayoutMarginsFollowReadableWidth = YES.
    // This conflicts with our desired layout margins, so set it to NO.
    if ([tableView respondsToSelector:@selector(setCellLayoutMarginsFollowReadableWidth:)]) {
        [tableView setCellLayoutMarginsFollowReadableWidth:NO];
    }
}

@end
