#import "WPActivityDefaults.h"
#import "SafariActivity.h"
#import "WordPressActivity.h"
#import "BlogService.h"
#import "ContextManager.h"

@implementation WPActivityDefaults

+ (NSArray *)defaultActivities
{
    SafariActivity *safariActivity = [[SafariActivity alloc] init];
    WordPressActivity *wordPressActivity = [[WordPressActivity alloc] init];

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *service = [[BlogService alloc] initWithManagedObjectContext:context];
    NSInteger visibleBlogs = [service blogCountVisibleForAllAccounts];

    if (visibleBlogs > 0) {
        return @[safariActivity, wordPressActivity];
    } else {
        return @[safariActivity];
    }
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
    } else if ([activityType isEqualToString:NSStringFromClass([WordPressActivity class])]) {
        stat = WPAnalyticsStatSentItemToWordPress;
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
