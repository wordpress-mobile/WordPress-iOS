//
//  WPMobileStats.h
//  WordPress
//
//  Created by Sendhil Panchadsaram on 5/14/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <Foundation/Foundation.h>

// General
extern NSString *const StatsAppOpened;

// NUX Related
extern NSString *const StatsEventNUXFirstWalkthroughOpened;
extern NSString *const StatsEventNUXFirstWalkthroughViewedPage2;
extern NSString *const StatsEventNUXFirstWalkthroughViewedPage3;
extern NSString *const StatsEventNUXFirstWalkthroughClickedSkipToCreateAccount;
extern NSString *const StatsEventNUXFirstWalkthroughClickedSkipToSignIn;
extern NSString *const StatsEventNUXFirstWalkthroughClickedInfo;
extern NSString *const StatsEventNUXFirstWalkthroughClickedCreateAccount;
extern NSString *const StatsEventNUXFirstWalkthroughSignedInWithoutUrl;
extern NSString *const StatsEventNUXFirstWalkthroughSignedInWithUrl;
extern NSString *const StatsEventNUXFirstWalkthroughSignedInForDotCom;
extern NSString *const StatsEventNUXFirstWalkthroughSignedInForSelfHosted;
extern NSString *const StatsEventNUXFirstWalkthroughClickedNeededHelpOnError;

// NUX Create Account
extern NSString *const StatsEventNUXCreateAccountOpened;
extern NSString *const StatsEventNUXCreateAccountClickedCancel;
extern NSString *const StatsEventNUXCreateAccountClickedHelp;
extern NSString *const StatsEventNUXCreateAccountClickedPage1Next;
extern NSString *const StatsEventNUXCreateAccountClickedPage2Next;
extern NSString *const StatsEventNUXCreateAccountClickedPage2Previous;
extern NSString *const StatsEventNUXCreateAccountCreatedAccount;
extern NSString *const StatsEventNUXCreateAccountClickedPage3Previous;
extern NSString *const StatsEventNUXCreateAccountClickedViewLanguages;
extern NSString *const StatsEventNUXCreateAccountChangedDefaultURL;

// NUX Second Walkthrough
extern NSString *const StatsEventNUXSecondWalkthroughOpened;
extern NSString *const StatsEventNUXSecondWalkthroughViewedPage2;
extern NSString *const StatsEventNUXSecondWalkthroughViewedPage3;
extern NSString *const StatsEventNUXSecondWalkthroughViewedPage4;
extern NSString *const StatsEventNUXSecondWalkthroughClickedStartUsingApp;
extern NSString *const StatsEventNUXSecondWalkthroughClickedStartUsingAppOnFinalPage;

// Add Blogs
extern NSString *const StatsEventAddBlogsOpened;
extern NSString *const StatsEventAddBlogsClickedSelectAll;
extern NSString *const StatsEventAddBlogsClickedDeselectAll;
extern NSString *const StatsEventAddBlogsClickedAddSelected;

@interface WPMobileStats : NSObject

+ (void)initializeStats;

+ (void)trackEventForSelfHostedAndWPCom:(NSString *)event;
+ (void)trackEventForSelfHostedAndWPCom:(NSString *)event properties:(NSDictionary *)properties;
+ (void)trackEventForWPCom:(NSString *)event;
+ (void)trackEventForWPCom:(NSString *)event properties:(NSDictionary *)properties;

@end
