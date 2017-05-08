#import "AppExtensionUtils.h"

@implementation AppExtensionUtils

+ (void)openURL:(NSURL *)url fromController:(UIViewController *)viewController {
    if (viewController.extensionContext != nil) {
        [viewController.extensionContext openURL:url completionHandler:nil];
    } else {
        NSObject *application = [UIApplication performSelector:@selector(sharedApplication)];
        [application performSelector:@selector(openURL: ) withObject:url];

    }
}

+ (void)setNetworkActivityIndicatorVisible:(BOOL)active fromController:(UIViewController *)viewController {
    if (viewController.extensionContext == nil) {
        NSObject *application = [UIApplication performSelector:@selector(sharedApplication)];
        NSInvocation *invocation = [[NSInvocation alloc] init];
        invocation.selector = @selector(setNetworkActivityIndicatorVisible:);
        [invocation setArgument:&active atIndex:0];
        [invocation invokeWithTarget:application];
    }
}

@end
