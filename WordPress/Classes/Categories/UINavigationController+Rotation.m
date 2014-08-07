#import "UINavigationController+Rotation.h"
#import <objc/runtime.h>

@implementation UINavigationController (Rotation)

- (NSUInteger)mySupportedInterfaceOrientations
{
    // Respect the top child's orientation prefs.
    if ([self respondsToSelector:@selector(topViewController)] && self.topViewController && [self.topViewController respondsToSelector:@selector(supportedInterfaceOrientations)]) {
        return [self.topViewController supportedInterfaceOrientations];
    }

    if (IS_IPHONE) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)myShouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    NSUInteger mask = [self mySupportedInterfaceOrientations];
    NSUInteger orientation = 1 << toInterfaceOrientation;

    return mask & orientation;
}

- (BOOL)myShouldAutoRotate
{
    if ([self respondsToSelector:@selector(topViewController)] && self.topViewController && [self.topViewController respondsToSelector:@selector(shouldAutorotate)]) {
        return [self.topViewController shouldAutorotate];
    }
    return YES;
}

+ (void)load
{
    Method origMethod = class_getInstanceMethod(self, @selector(supportedInterfaceOrientations));
    Method newMethod = class_getInstanceMethod(self, @selector(mySupportedInterfaceOrientations));
    method_exchangeImplementations(origMethod, newMethod);

    origMethod = class_getInstanceMethod(self, @selector(shouldAutorotate));
    newMethod = class_getInstanceMethod(self, @selector(myShouldAutoRotate));
    method_exchangeImplementations(origMethod, newMethod);

    origMethod = class_getInstanceMethod(self, @selector(shouldAutorotateToInterfaceOrientation:));
    newMethod = class_getInstanceMethod(self, @selector(myShouldAutorotateToInterfaceOrientation:));
    method_exchangeImplementations(origMethod, newMethod);
}

@end
