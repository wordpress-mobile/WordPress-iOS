#import "SafariActivity.h"

@implementation SafariActivity {
    NSURL *_URL;
}

- (UIImage *)activityImage
{
    return [UIImage systemImageNamed:@"safari"];
}

- (NSString *)activityTitle
{
    return NSLocalizedString(@"Open in Safari", @"");
}

- (NSString *)activityType
{
    return NSStringFromClass([self class]);
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    for (id activityItem in activityItems) {
        if ([activityItem isKindOfClass:[NSURL class]] && [[UIApplication sharedApplication] canOpenURL:activityItem]) {
            return YES;
        }
    }

    return NO;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems
{
    for (id activityItem in activityItems) {
        if ([activityItem isKindOfClass:[NSURL class]]) {
            _URL = activityItem;
        }
    }
}

- (void)performActivity
{
    [[UIApplication sharedApplication] openURL:_URL options:nil completionHandler:^(BOOL success) {
        [self activityDidFinish:success];
    }];


}

@end
