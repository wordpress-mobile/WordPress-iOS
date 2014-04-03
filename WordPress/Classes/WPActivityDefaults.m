//
//  WPActivityDefaults.m
//  WordPress
//
//  Created by Jorge Bernal on 7/26/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

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

+ (void)trackActivityType:(NSString *)activityType withPrefix:(NSString *)prefix
{
    NSString *event;
    NSString *superProperty;
    if ([activityType isEqualToString:UIActivityTypeMail]) {
        event = StatsEventWebviewSharedArticleViaEmail;
        superProperty = StatsSuperPropertyNumberOfItemsSharedViaEmail;
    } else if ([activityType isEqualToString:UIActivityTypeMessage]) {
        event = StatsEventWebviewSharedArticleViaSMS;
        superProperty = StatsSuperPropertyNumberOfItemsSharedViaSMS;
    } else if ([activityType isEqualToString:UIActivityTypePostToTwitter]) {
        event = StatsEventWebviewSharedArticleViaTwitter;
        superProperty = StatsSuperPropertyNumberOfItemsSharedViaTwitter;
    } else if ([activityType isEqualToString:UIActivityTypePostToFacebook]) {
        event = StatsEventWebviewSharedArticleViaFacebook;
        superProperty = StatsSuperPropertyNumberOfItemsSharedViaFacebook;
    } else if ([activityType isEqualToString:UIActivityTypeCopyToPasteboard]) {
        event = StatsEventWebviewCopiedArticleDetails;
    } else if ([activityType isEqualToString:UIActivityTypePostToWeibo]) {
        event = StatsEventWebviewSharedArticleViaWeibo;
        superProperty = StatsSuperPropertyNumberOfItemsSharedViaWeibo;
    } else if ([activityType isEqualToString:NSStringFromClass([SafariActivity class])]) {
        event = StatsEventWebviewOpenedArticleInSafari;
    } else if ([activityType isEqualToString:NSStringFromClass([InstapaperActivity class])]) {
        event = StatsEventWebviewSentArticleToInstapaper;
        superProperty = StatsSuperPropertyNumberOfItemsSentToInstapaper;
    } else if ([activityType isEqualToString:NSStringFromClass([PocketActivity class])]) {
        event = StatsEventWebviewSentArticleToPocket;
        superProperty = StatsSuperPropertyNumberOfItemsSentToPocket;
    } else if ([activityType isEqualToString:NSStringFromClass([GooglePlusActivity class])]) {
        event = StatsEventWebviewSentArticleToGooglePlus;
        superProperty = StatsSuperPropertyNumberOfItemsSentToGooglePlus;
    }

    if (event != nil) {
        event = [NSString stringWithFormat:@"%@ - %@", prefix, event];
        [WPMobileStats trackEventForWPCom:event];
    }
    
    if (superProperty != nil) {
        [WPMobileStats incrementPeopleAndSuperProperty:superProperty];
        [WPMobileStats incrementPeopleAndSuperProperty:StatsSuperPropertyNumberOfItemsShared];
    }
}

@end
