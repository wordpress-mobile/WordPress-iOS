#import "WPActivityDefaults.h"

#import "SafariActivity.h"
#import "InstapaperActivity.h"
#import "PocketActivity.h"
#import "GooglePlusActivity.h"

@implementation WPActivityDefaults

+ (NSArray *)defaultActivities
{
    SafariActivity *safariActivity = [[SafariActivity alloc] init];
    InstapaperActivity *instapaperActivity = [[InstapaperActivity alloc] init];
    PocketActivity *pocketActivity = [[PocketActivity alloc] init];
    GooglePlusActivity *googlePlusActivity = [[GooglePlusActivity alloc] init];

    return @[safariActivity, instapaperActivity, pocketActivity, googlePlusActivity];
}

+ (void)trackActivityType:(NSString *)activityType
{
    WPStat stat;
    if ([activityType isEqualToString:UIActivityTypeMail]) {
        stat = WPStatSharedItemViaEmail;
    } else if ([activityType isEqualToString:UIActivityTypeMessage]) {
        stat = WPStatSharedItemViaSMS;
    } else if ([activityType isEqualToString:UIActivityTypePostToTwitter]) {
        stat = WPStatSharedItemViaTwitter;
    } else if ([activityType isEqualToString:UIActivityTypePostToFacebook]) {
        stat = WPStatSharedItemViaFacebook;
    } else if ([activityType isEqualToString:UIActivityTypePostToWeibo]) {
        stat = WPStatSharedItemViaWeibo;
    } else if ([activityType isEqualToString:NSStringFromClass([InstapaperActivity class])]) {
        stat = WPStatSentItemToInstapaper;
    } else if ([activityType isEqualToString:NSStringFromClass([PocketActivity class])]) {
        stat = WPStatSentItemToPocket;
    } else if ([activityType isEqualToString:NSStringFromClass([GooglePlusActivity class])]) {
        stat = WPStatSentItemToGooglePlus;
    } else {
        [WPStats track:WPStatSharedItem];
        return;
    }
    
    if (stat != WPStatNoStat) {
        [WPStats track:WPStatSharedItem];
        [WPStats track:stat];
    }
}

@end
