//
//  WPAppAnalytics.m
//  WordPress
//
//  Created by Diego E. Rey Mendez on 3/16/15.
//  Copyright (c) 2015 WordPress. All rights reserved.
//

#import "WPAppAnalytics.h"

#import "WPAnalyticsTrackerMixpanel.h"
#import "WPAnalyticsTrackerWPCom.h"
#import "WPTabBarController.h"
#import "WordPressComApiCredentials.h"

NSString* const WPAppAnalyticsDefaultsKeyUsageTracking = @"usage_tracking_enabled";
static NSString* const WPAppAnalyticsKeyLastVisibleScreen = @"last_visible_screen";
static NSString* const WPAppAnalyticsKeyTimeInApp = @"time_in_app";

@interface WPAppAnalytics ()
@property (nonatomic, strong, readwrite) NSDate* applicationOpenedTime;
@end

@implementation WPAppAnalytics

#pragma mark - Init

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        [self initializeAppTracking];
    }
    
    return self;
}

#pragma mark - Init helpers

/**
 *  @brief      Initializes analytics tracking for WPiOS.
 */
- (void)initializeAppTracking
{
    NSNumber* usageTracking = [[NSUserDefaults standardUserDefaults] valueForKey:WPAppAnalyticsDefaultsKeyUsageTracking];
    
    if (usageTracking == nil) {        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:WPAppAnalyticsDefaultsKeyUsageTracking];
        [NSUserDefaults resetStandardUserDefaults];
    }
    
    if ([WordPressComApiCredentials mixpanelAPIToken].length > 0) {
        [WPAnalytics registerTracker:[[WPAnalyticsTrackerMixpanel alloc] init]];
    }
    
    [WPAnalytics registerTracker:[[WPAnalyticsTrackerWPCom alloc] init]];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:WPAppAnalyticsDefaultsKeyUsageTracking]) {
        DDLogInfo(@"WPAnalytics session started");
        
        [WPAnalytics beginSession];
    }
}

#pragma mark - App Tracking

- (void)trackApplicationClosed:(NSString*)lastVisibleScreen
{
    NSMutableDictionary *analyticsProperties = [NSMutableDictionary new];
    
    if (lastVisibleScreen) {
        analyticsProperties[WPAppAnalyticsKeyLastVisibleScreen] = lastVisibleScreen;
    }
    
    if (self.applicationOpenedTime != nil) {
        NSDate *applicationClosedTime = [NSDate date];
        NSTimeInterval timeInApp = round([applicationClosedTime timeIntervalSinceDate:self.applicationOpenedTime]);
        analyticsProperties[WPAppAnalyticsKeyTimeInApp] = @(timeInApp);
        self.applicationOpenedTime = nil;
    }
    
    [WPAnalytics track:WPAnalyticsStatApplicationClosed withProperties:analyticsProperties];
    [WPAnalytics endSession];
}

- (void)trackApplicationOpened
{
    self.applicationOpenedTime = [NSDate date];
    [WPAnalytics track:WPAnalyticsStatApplicationOpened];
}

@end
