#import "UIViewController+SizeClass.h"

@implementation UIViewController (SizeClass)

- (BOOL)isViewHorizontallyCompact
{
    return self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact;
}

@end
