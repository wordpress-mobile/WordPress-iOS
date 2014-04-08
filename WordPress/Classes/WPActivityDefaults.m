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
    NSString *superProperty;
    if ([activityType isEqualToString:UIActivityTypeMail]) {
        superProperty = StatsSuperPropertyNumberOfItemsSharedViaEmail;
    } else if ([activityType isEqualToString:UIActivityTypeMessage]) {
        superProperty = StatsSuperPropertyNumberOfItemsSharedViaSMS;
    } else if ([activityType isEqualToString:UIActivityTypePostToTwitter]) {
        superProperty = StatsSuperPropertyNumberOfItemsSharedViaTwitter;
    } else if ([activityType isEqualToString:UIActivityTypePostToFacebook]) {
        superProperty = StatsSuperPropertyNumberOfItemsSharedViaFacebook;
    } else if ([activityType isEqualToString:UIActivityTypeCopyToPasteboard]) {
    } else if ([activityType isEqualToString:UIActivityTypePostToWeibo]) {
        superProperty = StatsSuperPropertyNumberOfItemsSharedViaWeibo;
    } else if ([activityType isEqualToString:NSStringFromClass([InstapaperActivity class])]) {
        superProperty = StatsSuperPropertyNumberOfItemsSentToInstapaper;
    } else if ([activityType isEqualToString:NSStringFromClass([PocketActivity class])]) {
        superProperty = StatsSuperPropertyNumberOfItemsSentToPocket;
    } else if ([activityType isEqualToString:NSStringFromClass([GooglePlusActivity class])]) {
        superProperty = StatsSuperPropertyNumberOfItemsSentToGooglePlus;
    }
    
    if (superProperty != nil) {
        [WPMobileStats incrementPeopleAndSuperProperty:superProperty];
        [WPMobileStats incrementPeopleAndSuperProperty:StatsSuperPropertyNumberOfItemsShared];
    }
}

@end
