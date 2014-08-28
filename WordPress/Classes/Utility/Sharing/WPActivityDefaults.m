#import "WPActivityDefaults.h"

#import "SafariActivity.h"
#import "InstapaperActivity.h"
#import "PocketActivity.h"
#import "GooglePlusActivity.h"
#import "WordPressActivity.h"

@implementation WPActivityDefaults

+ (NSArray *)defaultActivities
{
    SafariActivity *safariActivity = [[SafariActivity alloc] init];
    InstapaperActivity *instapaperActivity = [[InstapaperActivity alloc] init];
    PocketActivity *pocketActivity = [[PocketActivity alloc] init];
    GooglePlusActivity *googlePlusActivity = [[GooglePlusActivity alloc] init];
    WordPressActivity *wordPressActivity = [[WordPressActivity alloc] init];

    return @[safariActivity, wordPressActivity, instapaperActivity, pocketActivity, googlePlusActivity];
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
    } else if ([activityType isEqualToString:NSStringFromClass([InstapaperActivity class])]) {
        stat = WPAnalyticsStatSentItemToInstapaper;
    } else if ([activityType isEqualToString:NSStringFromClass([PocketActivity class])]) {
        stat = WPAnalyticsStatSentItemToPocket;
    } else if ([activityType isEqualToString:NSStringFromClass([GooglePlusActivity class])]) {
        stat = WPAnalyticsStatSentItemToGooglePlus;
    } else if ([activityType isEqualToString:NSStringFromClass([WordPressActivity class])]) {
        stat = WPAnalyticsStatSentItemToWordPress;
    } else if ([activityType isEqualToString:UIActivityTypeCopyToPasteboard] || [activityType isEqualToString:UIActivityTypeAddToReadingList] || [activityType isEqualToString:NSStringFromClass([SafariActivity class])]) {
        return;
    } else {
        [WPAnalytics track:WPAnalyticsStatSharedItem];
        return;
    }

    if (stat != WPAnalyticsStatNoStat) {
        [WPAnalytics track:WPAnalyticsStatSharedItem];
        [WPAnalytics track:stat];
    }
}

@end
