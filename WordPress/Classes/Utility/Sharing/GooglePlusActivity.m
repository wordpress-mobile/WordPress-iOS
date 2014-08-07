#import <SVProgressHUD/SVProgressHUD.h>
#import <GooglePlus/GooglePlus.h>

#import "GooglePlusActivity.h"

@interface GooglePlusActivity () <GPPShareDelegate>

@end

@implementation GooglePlusActivity {
    NSURL *_URL;
}

- (UIImage *)activityImage
{
    return [UIImage imageNamed:@"NNGPlusActivity"];
}

- (NSString *)activityTitle
{
    return @"Google+";
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
    [[GPPShare sharedInstance] setDelegate:self];
    id<GPPShareBuilder> shareBuilder = [[GPPShare sharedInstance] shareDialog];
    [shareBuilder setURLToShare:_URL];
    [shareBuilder open];
}

- (void)finishedSharing:(BOOL)shared
{
    [self activityDidFinish:shared];
}

@end
