#import <WordPressComAnalytics/WPAnalytics.h>
#import <XCTest/XCTest.h>

#import "WordPressAppDelegate.h"
#import "ApiCredentials.h"
#import "WPAppAnalytics.h"
#import "WPAnalyticsTrackerWPCom.h"
@import OCMock;

typedef void(^OCMockInvocationBlock)(NSInvocation* invocation);

@interface WPAppAnalyticsTests : XCTestCase
@end

@implementation WPAppAnalyticsTests

- (void)testInitializationWithWPComTracker
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:WPAppAnalyticsDefaultsKeyUsageTracking];
    
    id analyticsMock = [OCMockObject mockForClass:[WPAnalytics class]];
    id apiCredentialsMock = [OCMockObject mockForClass:[ApiCredentials class]];
    
    OCMockInvocationBlock registerTrackerInvocationBlock = ^(NSInvocation *invocation) {
        __unsafe_unretained id<WPAnalyticsTracker> tracker = nil;
        [invocation getArgument:&tracker atIndex:2];
        
        NSAssert([tracker isKindOfClass:[WPAnalyticsTrackerWPCom class]],
                 @"Expected to have a WPCom tracker.");
    };
    
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

- (void)testInitializationWithWPComTrackerButNoUsageTracking
{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:WPAppAnalyticsDefaultsKeyUsageTracking];
    
    id analyticsMock = [OCMockObject mockForClass:[WPAnalytics class]];
    id apiCredentialsMock = [OCMockObject mockForClass:[ApiCredentials class]];
    
    OCMockInvocationBlock registerTrackerInvocationBlock = ^(NSInvocation *invocation) {
        __unsafe_unretained id<WPAnalyticsTracker> tracker = nil;
        [invocation getArgument:&tracker atIndex:2];
        
        NSAssert([tracker isKindOfClass:[WPAnalyticsTrackerWPCom class]],
                 @"Expected to have a WPCom tracker.");
    };
    
    [[[analyticsMock expect] andDo:registerTrackerInvocationBlock] registerTracker:OCMOCK_ANY];
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
    WPAppAnalytics* analytics = [[WPAppAnalytics alloc] initWithLastVisibleScreenBlock:^NSString *{
        return nil;
    }];
    
    [analytics setTrackingUsage:YES];
    
    XCTAssertTrue([analytics isTrackingUsage]);
}

- (void)testIsNotTrackingUsage
{
    WPAppAnalytics* analytics = [[WPAppAnalytics alloc] initWithLastVisibleScreenBlock:^NSString *{
        return nil;
    }];
    
    [analytics setTrackingUsage:NO];
    
    XCTAssertFalse([analytics isTrackingUsage]);
}

@end
