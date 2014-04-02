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
    if ([activityType isEqualToString:UIActivityTypeMail]) {
        event = StatsEventWebviewSharedArticleViaEmail;
    } else if ([activityType isEqualToString:UIActivityTypeMessage]) {
        event = StatsEventWebviewSharedArticleViaSMS;
    } else if ([activityType isEqualToString:UIActivityTypePostToTwitter]) {
        event = StatsEventWebviewSharedArticleViaTwitter;
    } else if ([activityType isEqualToString:UIActivityTypePostToFacebook]) {
        event = StatsEventWebviewSharedArticleViaFacebook;
    } else if ([activityType isEqualToString:UIActivityTypeCopyToPasteboard]) {
        event = StatsEventWebviewCopiedArticleDetails;
    } else if ([activityType isEqualToString:UIActivityTypePostToWeibo]) {
        event = StatsEventWebviewSharedArticleViaWeibo;
    } else if ([activityType isEqualToString:NSStringFromClass([SafariActivity class])]) {
        event = StatsEventWebviewOpenedArticleInSafari;
    } else if ([activityType isEqualToString:NSStringFromClass([InstapaperActivity class])]) {
        event = StatsEventWebviewSentArticleToInstapaper;
    } else if ([activityType isEqualToString:NSStringFromClass([PocketActivity class])]) {
        event = StatsEventWebviewSentArticleToPocket;
    } else if ([activityType isEqualToString:NSStringFromClass([GooglePlusActivity class])]) {
        event = StatsEventWebviewSentArticleToGooglePlus;
    }

    if (event != nil) {
        event = [NSString stringWithFormat:@"%@ - %@", prefix, event];
        [WPMobileStats trackEventForWPCom:event];
    }
}




@end
