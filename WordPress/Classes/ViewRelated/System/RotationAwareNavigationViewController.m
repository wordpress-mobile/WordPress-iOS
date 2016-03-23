#import "RotationAwareNavigationViewController.h"
#import "WordPress-Swift.h"

@implementation RotationAwareNavigationViewController

- (BOOL)shouldAutorotate
{
    // Respect the top child's orientation prefs.
    if (self.topViewController && [self.topViewController respondsToSelector:@selector(shouldAutorotate)]) {
        return [self.topViewController shouldAutorotate];
    }
    
    return [super shouldAutorotate];
}

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
