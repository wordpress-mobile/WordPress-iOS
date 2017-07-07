#import "WPActivityDefaults.h"
#import "SafariActivity.h"
#import <WordPressShared/WPAnalytics.h>


@implementation WPActivityDefaults

+ (NSArray *)defaultActivities
{
    return @[[SafariActivity new]];
}

+ (void)trackActivityType:(NSString *)activityType
{
    WPAnalyticsStat stat;
    if ([activityType isEqualToString:UIActivityTypeMail]) {
        stat = WPAnalyticsStatSharedItemViaEmail;
    } else if ([activityType isEqualToString:UIActivityTypeMessage]) {
        stat = WPAnalyticsStatSharedItemViaSMS;
    } else if ([activityType isEqualToString:UIActivityTypePostToTwitter]) {
        stat = WPAnalyticsStatSharedItemViaTwitter;
    } else if ([activityType isEqualToString:UIActivityTypePostToFacebook]) {
        stat = WPAnalyticsStatSharedItemViaFacebook;
    } else if ([activityType isEqualToString:UIActivityTypePostToWeibo]) {
        stat = WPAnalyticsStatSharedItemViaWeibo;
    } else if ([activityType isEqualToString:@"com.marcoarment.instapaperpro.InstapaperSave"]) {
        stat = WPAnalyticsStatSentItemToInstapaper;
    } else if ([activityType isEqualToString:@"com.ideashower.ReadItLaterPro.AddToPocketExtension"]) {
        stat = WPAnalyticsStatSentItemToPocket;
    } else if ([activityType isEqualToString:@"com.google.GooglePlus.ShareExtension"]) {
        stat = WPAnalyticsStatSentItemToGooglePlus;
    } else if ([activityType isEqualToString:UIActivityTypeCopyToPasteboard]) {
        return;
    } else {
        [WPAnalytics track:WPAnalyticsStatSharedItem withProperties:@{@"activity_type":activityType}];
        return;
    }

    if (stat != WPAnalyticsStatNoStat) {
        [WPAnalytics track:WPAnalyticsStatSharedItem];
        [WPAnalytics track:stat];
    }
}

@end
