#import "RotationAwareNavigationViewController.h"
#import "WordPress-Swift.h"

@implementation RotationAwareNavigationViewController

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    // Respect the top child's orientation prefs.
    if (self.topViewController && [self.topViewController respondsToSelector:@selector(supportedInterfaceOrientations)]) {
        return [self.topViewController supportedInterfaceOrientations];
    }
    
    if ([UIDevice isPad]) {
        return UIInterfaceOrientationMaskAll;
    }
    return UIInterfaceOrientationMaskAllButUpsideDown;
}


@end
