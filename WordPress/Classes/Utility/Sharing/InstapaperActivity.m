#import "InstapaperActivity.h"

@implementation InstapaperActivity {
    NSURL *_URL;
}

- (UIImage *)activityImage
{
    return [UIImage imageNamed:@"NNInstapaperActivity"];
}

- (NSString *)activityTitle
{
    return @"Instapaper";
}

- (NSString *)activityType
{
    return NSStringFromClass([self class]);
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    NSURL *URL = [self URLFromActivityItems:activityItems];
    return (URL && [[UIApplication sharedApplication] canOpenURL:URL]);
}

- (void)prepareWithActivityItems:(NSArray *)activityItems
{
    _URL = [self URLFromActivityItems:activityItems];
}

- (void)performActivity
{
    BOOL completed = [[UIApplication sharedApplication] openURL:_URL];

    [self activityDidFinish:completed];
}

- (NSURL *)URLFromActivityItems:(NSArray *)activityItems
{
    NSURL *URL = nil;
    for (id activityItem in activityItems) {
        if ([activityItem isKindOfClass:[NSURL class]]) {
            URL = [NSURL URLWithString:[NSString stringWithFormat:@"i%@", [activityItem absoluteString]]];
        }
    }
    return URL;
}

@end
