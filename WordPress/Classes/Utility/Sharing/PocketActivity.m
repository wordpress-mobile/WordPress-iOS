#import <SVProgressHUD/SVProgressHUD.h>

#import "PocketActivity.h"
#import "PocketAPI.h"

@implementation PocketActivity
{
    NSURL *_URL;
}

- (void)dealloc
{
    [self removeNotificationObserver];
}

- (UIImage *)activityImage
{
    return [UIImage imageNamed:@"NNPocketActivity"];
}

- (NSString *)activityTitle
{
    return @"Pocket";
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
    [SVProgressHUD show];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[PocketAPI sharedAPI] saveURL:_URL handler:^(PocketAPI *api, NSURL *url, NSError *error) {
        BOOL completed = (error == nil);
        if (completed) {
            [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:NSLocalizedString(@"Saved to %@", @""), [self activityTitle]]];
        } else {
            DDLogError(@"Failed saving to Pocket: %@ err: %@", url, error);
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Failed", @"")];
        }

        [self activityDidFinish:completed];
    }];
}

- (void)didEnterBackground:(NSNotification *)notification
{
    [SVProgressHUD dismiss];
    [self removeNotificationObserver];
}

- (void)removeNotificationObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}

@end
