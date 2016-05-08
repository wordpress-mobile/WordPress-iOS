#import <OCMock/OCMock.h>
#import <WordPressComAnalytics/WPAnalytics.h>
#import <XCTest/XCTest.h>

#import "WordPressAppDelegate.h"
#import "WordPressComApiCredentials.h"
#import "WPAppAnalytics.h"
#import "WPAnalyticsTrackerMixpanel.h"
#import "WPAnalyticsTrackerWPCom.h"

typedef void(^OCMockInvocationBlock)(NSInvocation* invocation);

@interface WPAppAnalyticsTests : XCTestCase
@end

@implementation WPAppAnalyticsTests

- (void)testInitializationWithMixpanelAndWPComTracker
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:WPAppAnalyticsDefaultsKeyUsageTracking];
    
    id analyticsMock = [OCMockObject mockForClass:[WPAnalytics class]];
    id apiCredentialsMock = [OCMockObject mockForClass:[WordPressComApiCredentials class]];
    
    OCMockInvocationBlock firstRegisterTrackerInvocationBlock = ^(NSInvocation *invocation) {
        __unsafe_unretained id<WPAnalyticsTracker> tracker = nil;
        [invocation getArgument:&tracker atIndex:2];
        
        NSAssert([tracker isKindOfClass:[WPAnalyticsTrackerMixpanel class]],
                 @"Expected to have a mixpanel tracker.");
    };
    
    OCMockInvocationBlock secondRegisterTrackerInvocationBlock = ^(NSInvocation *invocation) {
        __unsafe_unretained id<WPAnalyticsTracker> tracker = nil;
        [invocation getArgument:&tracker atIndex:2];
        
        NSAssert([tracker isKindOfClass:[WPAnalyticsTrackerWPCom class]],
                 @"Expected to have a WPCom tracker.");
    };
    
    [[[apiCredentialsMock expect] andReturn:@"NON_EMPTY_TOKEN"] mixpanelAPIToken];
    [[[analyticsMock expect] andDo:firstRegisterTrackerInvocationBlock] registerTracker:OCMOCK_ANY];
    [[[analyticsMock expect] andDo:secondRegisterTrackerInvocationBlock] registerTracker:OCMOCK_ANY];
    [[analyticsMock expect] beginSession];
    
    WPAppAnalytics *analytics = nil;
    WPAppAnalyticsLastVisibleScreenCallback lastVisibleScreenCallback = ^NSString*{
        return @"TEST";
    };
    
    XCTAssertNoThrow(analytics = [[WPAppAnalytics alloc] initWithLastVisibleScreenBlock:lastVisibleScreenCallback],
                     @"Allocating or initializing this object shouldn't throw an exception");
    XCTAssert([analytics isKindOfClass:[WPAppAnalytics class]]);
    
    [apiCredentialsMock verify];
    [analyticsMock verify];
    
    [apiCredentialsMock stopMocking];
    [analyticsMock stopMocking];
}

- (void)testInitializationWithWPComTracker
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:WPAppAnalyticsDefaultsKeyUsageTracking];
    
    id analyticsMock = [OCMockObject mockForClass:[WPAnalytics class]];
    id apiCredentialsMock = [OCMockObject mockForClass:[WordPressComApiCredentials class]];
    
    OCMockInvocationBlock registerTrackerInvocationBlock = ^(NSInvocation *invocation) {
        __unsafe_unretained id<WPAnalyticsTracker> tracker = nil;
        [invocation getArgument:&tracker atIndex:2];
        
        NSAssert([tracker isKindOfClass:[WPAnalyticsTrackerWPCom class]],
                 @"Expected to have a WPCom tracker.");
    };
    
    [[[apiCredentialsMock expect] andReturn:@""] mixpanelAPIToken];
    [[[analyticsMock expect] andDo:registerTrackerInvocationBlock] registerTracker:OCMOCK_ANY];
    [[analyticsMock expect] beginSession];
    
    WPAppAnalytics *analytics = nil;
    WPAppAnalyticsLastVisibleScreenCallback lastVisibleScreenCallback = ^NSString*{
        return @"TEST";
    };
    
    XCTAssertNoThrow(analytics = [[WPAppAnalytics alloc] initWithLastVisibleScreenBlock:lastVisibleScreenCallback],
                     @"Allocating or initializing this object shouldn't throw an exception");
    XCTAssert([analytics isKindOfClass:[WPAppAnalytics class]]);
    
    [apiCredentialsMock verify];
    [analyticsMock verify];
}

- (void)testInitializationWithMixpanelAndWPComTrackerButNoUsageTracking
{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:WPAppAnalyticsDefaultsKeyUsageTracking];
    
    id analyticsMock = [OCMockObject mockForClass:[WPAnalytics class]];
    id apiCredentialsMock = [OCMockObject mockForClass:[WordPressComApiCredentials class]];
    
    OCMockInvocationBlock firstRegisterTrackerInvocationBlock = ^(NSInvocation *invocation) {
        __unsafe_unretained id<WPAnalyticsTracker> tracker = nil;
        [invocation getArgument:&tracker atIndex:2];
        
        NSAssert([tracker isKindOfClass:[WPAnalyticsTrackerMixpanel class]],
                 @"Expected to have a mixpanel tracker.");
    };
    
    OCMockInvocationBlock secondRegisterTrackerInvocationBlock = ^(NSInvocation *invocation) {
        __unsafe_unretained id<WPAnalyticsTracker> tracker = nil;
        [invocation getArgument:&tracker atIndex:2];
        
        NSAssert([tracker isKindOfClass:[WPAnalyticsTrackerWPCom class]],
                 @"Expected to have a WPCom tracker.");
    };
    
    [[[apiCredentialsMock expect] andReturn:@"NON_EMPTY_TOKEN"] mixpanelAPIToken];
    [[[analyticsMock expect] andDo:firstRegisterTrackerInvocationBlock] registerTracker:OCMOCK_ANY];
    [[[analyticsMock expect] andDo:secondRegisterTrackerInvocationBlock] registerTracker:OCMOCK_ANY];
    [[analyticsMock reject] beginSession];
    
    WPAppAnalytics *analytics = nil;
    WPAppAnalyticsLastVisibleScreenCallback lastVisibleScreenCallback = ^NSString*{
        return @"TEST";
    };
    
    XCTAssertNoThrow(analytics = [[WPAppAnalytics alloc] initWithLastVisibleScreenBlock:lastVisibleScreenCallback],
                     @"Allocating or initializing this object shouldn't throw an exception");
    XCTAssert([analytics isKindOfClass:[WPAppAnalytics class]]);
    
    [apiCredentialsMock verify];
    [analyticsMock verify];
    
    [apiCredentialsMock stopMocking];
    [analyticsMock stopMocking];
}

- (void)testIsTrackingUsage
{
    WPAppAnalytics* analytics = [WordPressAppDelegate sharedInstance].analytics;
    
    [analytics setTrackingUsage:YES];
    
    XCTAssertTrue([analytics isTrackingUsage]);
}

- (void)testIsNotTrackingUsage
{
    WPAppAnalytics* analytics = [WordPressAppDelegate sharedInstance].analytics;
    
    [analytics setTrackingUsage:NO];
    
    XCTAssertFalse([analytics isTrackingUsage]);
}

@end
