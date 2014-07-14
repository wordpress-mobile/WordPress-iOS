#import "UITableView+Helpers.h"

@implementation UITableView (Helpers)

- (void)deselectSelectedRowWithAnimation:(BOOL)animation
{
    NSIndexPath *selectedRowIndexPath = self.indexPathForSelectedRow;
    if (selectedRowIndexPath) {
        [self deselectRowAtIndexPath:selectedRowIndexPath animated:animation];
    }
}

@end
