//
// Copyright (c) 2014 Mixpanel. All rights reserved.

#import "MPApplicationStateSerializer.h"
#import "MPObjectSerializer.h"
#import "MPClassDescription.h"
#import "MPObjectSerializerConfig.h"
#import "MPObjectIdentityProvider.h"
#import <QuartzCore/QuartzCore.h>

@implementation MPApplicationStateSerializer

{
    MPObjectSerializer *_serializer;
    UIApplication *_application;
}

- (id)initWithApplication:(UIApplication *)application configuration:(MPObjectSerializerConfig *)configuration objectIdentityProvider:(MPObjectIdentityProvider *)objectIdentityProvider
{
    NSParameterAssert(application != nil);
    NSParameterAssert(configuration != nil);

    self = [super init];
    if (self) {
        _application = application;
        _serializer = [[MPObjectSerializer alloc] initWithConfiguration:configuration objectIdentityProvider:objectIdentityProvider];
    }

    return self;
}

- (UIImage *)screenshotImageForWindowAtIndex:(NSUInteger)index
{
    UIImage *image = nil;

    UIWindow *window = [self windowAtIndex:index];
    if (window) {
        UIGraphicsBeginImageContextWithOptions(window.bounds.size, YES, window.screen.scale);
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
        if ([window respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
            if ([window drawViewHierarchyInRect:window.bounds afterScreenUpdates:YES] == NO) {
                NSLog(@"Unable to get complete screenshot for window at index: %d.", (int)index);
            }
        } else {
            [window.layer renderInContext:UIGraphicsGetCurrentContext()];
        }
#else
        [window.layer renderInContext:UIGraphicsGetCurrentContext()];
#endif
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }

    return image;
}

- (UIWindow *)windowAtIndex:(NSUInteger)index
{
    NSParameterAssert(index < [_application.windows count]);
    return _application.windows[index];
}

- (NSDictionary *)objectHierarchyForWindowAtIndex:(NSUInteger)index
{
    UIWindow *window = [self windowAtIndex:index];
    if (window) {
        return [_serializer serializedObjectsWithRootObject:window];
    }

    return @{};
}

@end
