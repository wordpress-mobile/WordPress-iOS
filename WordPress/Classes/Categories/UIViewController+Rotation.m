#import "UIViewController+Rotation.h"
#import <objc/runtime.h>

@implementation UIViewController (Rotation)

- (BOOL)myShouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ( IS_IPHONE && interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown ) {
        return NO;
    }

    return YES;
}

+ (void)load
{
    Method origMethod = class_getInstanceMethod(self, @selector(shouldAutorotateToInterfaceOrientation:));
    Method newMethod = class_getInstanceMethod(self, @selector(myShouldAutorotateToInterfaceOrientation:));
    method_exchangeImplementations(origMethod, newMethod);
}
@end
