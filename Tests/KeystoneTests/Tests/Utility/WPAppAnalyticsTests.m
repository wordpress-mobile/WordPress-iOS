#import <XCTest/XCTest.h>

#import "AccountService.h"
#import "WPAppAnalytics.h"
#import "WPAnalyticsTrackerWPCom.h"

@import OCMock;

typedef void(^OCMockInvocationBlock)(NSInvocation* invocation);

@interface WPAppAnalyticsTests : XCTestCase
@end

@implementation WPAppAnalyticsTests

- (void)setUp {
    [super setUp];

    WPAnalyticsTesting.eventNamePrefix = @"xctest";
    WPAnalyticsTesting.explatPlatform = @"xctest";
    WPAnalyticsTesting.appURLScheme = @"xctest";
}

- (void)tearDown {
    [super tearDown];

    WPAnalyticsTesting.eventNamePrefix = nil;
    WPAnalyticsTesting.explatPlatform = nil;
    WPAnalyticsTesting.appURLScheme = nil;

    [WPAnalytics clearTrackers];
}

- (void)testInitializationWithWPComTracker
{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:WPAppAnalyticsDefaultsUserOptedOut];

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

    XCTAssertNoThrow(analytics = [WPAppAnalytics new], @"Allocating or initializing this object shouldn't throw an exception");
    XCTAssert([analytics isKindOfClass:[WPAppAnalytics class]]);
    
    [apiCredentialsMock verify];
    [analyticsMock verify];
}

- (void)testInitializationWithWPComTrackerButUserOptedOut
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:WPAppAnalyticsDefaultsUserOptedOut];
    
    id analyticsMock = [OCMockObject mockForClass:[WPAnalytics class]];
    id apiCredentialsMock = [OCMockObject mockForClass:[ApiCredentials class]];

    [[analyticsMock reject] beginSession];
    
    WPAppAnalytics *analytics = nil;

    XCTAssertNoThrow(analytics = [WPAppAnalytics new], @"Allocating or initializing this object shouldn't throw an exception");
    XCTAssert([analytics isKindOfClass:[WPAppAnalytics class]]);

    [apiCredentialsMock verify];
    [analyticsMock verify];
    
    [apiCredentialsMock stopMocking];
    [analyticsMock stopMocking];
}

- (void)testUserOptedOut
{
    WPAppAnalytics *analytics = nil;

    XCTAssertNoThrow(analytics = [WPAppAnalytics new], @"Allocating or initializing this object shouldn't throw an exception");
    XCTAssert([analytics isKindOfClass:[WPAppAnalytics class]]);

    [analytics setUserHasOptedOut:YES];
    
    XCTAssertTrue([WPAppAnalytics userHasOptedOut]);
}

- (void)testUserHasNotOptedOut
{
    WPAppAnalytics *analytics = nil;

    XCTAssertNoThrow(analytics = [WPAppAnalytics new], @"Allocating or initializing this object shouldn't throw an exception");
    XCTAssert([analytics isKindOfClass:[WPAppAnalytics class]]);

    [analytics setUserHasOptedOut:NO];
    
    XCTAssertFalse([WPAppAnalytics userHasOptedOut]);
}

@end
