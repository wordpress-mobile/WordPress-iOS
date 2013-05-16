//
//  WPMobileStats.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 5/14/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPMobileStats.h"
#import <Mixpanel/Mixpanel.h>
#import "WordPressComApiCredentials.h"
#import "WordPressComApi.h"

// General
NSString *const StatsAppOpened = @"Application Opened";

// NUX First Walkthrough 
NSString *const StatsEventNUXFirstWalkthroughOpened = @"NUX - First Walkthrough - Opened";
NSString *const StatsEventNUXFirstWalkthroughViewedPage2 = @"NUX - First Walkthrough - Viewed Page 2";
NSString *const StatsEventNUXFirstWalkthroughViewedPage3 = @"NUX - First Walkthrough - Viewed Page 3";
NSString *const StatsEventNUXFirstWalkthroughClickedSkipToCreateAccount = @"NUX - First Walkthrough - Skipped to Create Account";
NSString *const StatsEventNUXFirstWalkthroughClickedSkipToSignIn = @"NUX - First Walkthrough - Skipped to Sign In";
NSString *const StatsEventNUXFirstWalkthroughClickedInfo = @"NUX - First Walkthrough - Clicked Info";
NSString *const StatsEventNUXFirstWalkthroughClickedCreateAccount = @"NUX - First Walkthrough - Clicked Create Account";
NSString *const StatsEventNUXFirstWalkthroughSignedInWithoutUrl = @"NUX - First Walkthrough - Signed In Without URL";
NSString *const StatsEventNUXFirstWalkthroughSignedInWithUrl = @"NUX - First Walkthrough - Signed In With URL";
NSString *const StatsEventNUXFirstWalkthroughSignedInForDotCom = @"NUX - First Walkthrough - Signed In For WordPress.com";
NSString *const StatsEventNUXFirstWalkthroughSignedInForSelfHosted = @"NUX - First Walkthrough - Signed In For Self Hosted Site";
NSString *const StatsEventNUXFirstWalkthroughClickedNeededHelpOnError = @"NUX - First Walkthrough - Clicked Needed Help on Error";

// NUX Create Account
NSString *const StatsEventNUXCreateAccountOpened = @"NUX - Create Account - Opened";
NSString *const StatsEventNUXCreateAccountClickedCancel = @"NUX - Create Account - Clicked Cancel";
NSString *const StatsEventNUXCreateAccountClickedHelp = @"NUX - Create Account - Clicked Help";
NSString *const StatsEventNUXCreateAccountClickedPage1Next = @"NUX - Create Account - Clicked Page 1 Next";
NSString *const StatsEventNUXCreateAccountClickedPage2Next = @"NUX - Create Account - Clicked Page 2 Next";
NSString *const StatsEventNUXCreateAccountClickedPage2Previous = @"NUX - Create Account - Clicked Page 2 Previous";
NSString *const StatsEventNUXCreateAccountCreatedAccount = @"NUX - Create Account - Created Account";
NSString *const StatsEventNUXCreateAccountClickedPage3Previous = @"NUX - Create Account - Clicked Page 3 Previous";
NSString *const StatsEventNUXCreateAccountClickedViewLanguages = @"NUX - Create Account - Viewed Languages";
NSString *const StatsEventNUXCreateAccountChangedDefaultURL = @"NUX - Create Account - Changed Default URL";

// NUX Second Walkthrough
NSString *const StatsEventNUXSecondWalkthroughOpened = @"NUX - Second Walkthrough - Opened";
NSString *const StatsEventNUXSecondWalkthroughViewedPage2 = @"NUX - Second Walkthrough - Viewed Page 2";
NSString *const StatsEventNUXSecondWalkthroughViewedPage3 = @"NUX - Second Walkthrough - Viewed Page 3";
NSString *const StatsEventNUXSecondWalkthroughViewedPage4 = @"NUX - Second Walkthrough - Viewed Page 4";
NSString *const StatsEventNUXSecondWalkthroughClickedStartUsingApp = @"NUX - Second Walkthrough - Clicked Start Using App";
NSString *const StatsEventNUXSecondWalkthroughClickedStartUsingAppOnFinalPage = @"NUX - Second Walkthrough - Clicked Start Using App on Final Page";

// Ådd Blogs Screen
NSString *const StatsEventAddBlogsOpened = @"Add Blogs - Opened";
NSString *const StatsEventAddBlogsClickedSelectAll = @"Add Blogs - Clicked Select All";
NSString *const StatsEventAddBlogsClickedDeselectAll = @"Add Blogs - Clicked Deselect All";
NSString *const StatsEventAddBlogsClickedAddSelected = @"Add Blogs - Clicked Add Selected";

@implementation WPMobileStats

+ (void)initializeStats
{
    [Mixpanel sharedInstanceWithToken:[WordPressComApiCredentials mixpanelAPIToken]];
}

+ (void)trackEventForSelfHostedAndWPCom:(NSString *)event
{
    [[Mixpanel sharedInstance] track:event];
}

+ (void)trackEventForSelfHostedAndWPCom:(NSString *)event properties:(NSDictionary *)properties
{
    [[Mixpanel sharedInstance] track:event properties:properties];
}

+ (void)trackEventForWPCom:(NSString *)event
{
    if ([self connectedToWordPressDotCom]) {
        [[Mixpanel sharedInstance] track:event];
    }
}

+ (void)trackEventForWPCom:(NSString *)event properties:(NSDictionary *)properties
{
    if ([self connectedToWordPressDotCom]) {
        [[Mixpanel sharedInstance] track:event properties:properties];
    }
}

#pragma mark - Private Methods

+ (BOOL)connectedToWordPressDotCom
{
    return [[WordPressComApi sharedApi] hasCredentials];
}


@end
