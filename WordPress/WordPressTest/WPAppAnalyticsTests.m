#import <WordPressShared/WPAnalytics.h>
#import <XCTest/XCTest.h>

#import "AccountService.h"
#import "WPAppAnalytics.h"
#import "WPAnalyticsTrackerWPCom.h"
@import OCMock;

typedef void(^OCMockInvocationBlock)(NSInvocation* invocation);

@interface WPAppAnalyticsTests : XCTestCase
@end

@implementation WPAppAnalyticsTests

- (void)tearDown {
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
    WPAppAnalyticsLastVisibleScreenCallback lastVisibleScreenCallback = ^NSString*{
        return @"TEST";
    };
    
    XCTAssertNoThrow(analytics = [[WPAppAnalytics alloc] initWithLastVisibleScreenBlock:lastVisibleScreenCallback],
                     @"Allocating or initializing this object shouldn't throw an exception");
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

- (void)testUserOptedOut
{
    WPAppAnalytics *analytics = nil;
    WPAppAnalyticsLastVisibleScreenCallback lastVisibleScreenCallback = ^NSString*{
        return @"TEST";
    };

    XCTAssertNoThrow(analytics = [[WPAppAnalytics alloc] initWithLastVisibleScreenBlock:lastVisibleScreenCallback],
                     @"Allocating or initializing this object shouldn't throw an exception");
    XCTAssert([analytics isKindOfClass:[WPAppAnalytics class]]);

    [analytics setUserHasOptedOut:YES];
    
    XCTAssertTrue([WPAppAnalytics userHasOptedOut]);
}

- (void)testUserHasNotOptedOut
{
    WPAppAnalytics *analytics = nil;
    WPAppAnalyticsLastVisibleScreenCallback lastVisibleScreenCallback = ^NSString*{
        return @"TEST";
    };

    XCTAssertNoThrow(analytics = [[WPAppAnalytics alloc] initWithLastVisibleScreenBlock:lastVisibleScreenCallback],
                     @"Allocating or initializing this object shouldn't throw an exception");
    XCTAssert([analytics isKindOfClass:[WPAppAnalytics class]]);

    [analytics setUserHasOptedOut:NO];
    
    XCTAssertFalse([WPAppAnalytics userHasOptedOut]);
}

- (void)testOptOutMigrationWhenTrackingWasEnabled
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:WPAppAnalyticsDefaultsUserOptedOut];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:WPAppAnalyticsDefaultsKeyUsageTracking_deprecated];

    WPAppAnalytics *analytics = nil;
    WPAppAnalyticsLastVisibleScreenCallback lastVisibleScreenCallback = ^NSString*{
        return @"TEST";
    };

    XCTAssertNoThrow(analytics = [[WPAppAnalytics alloc] initWithLastVisibleScreenBlock:lastVisibleScreenCallback],
                     @"Allocating or initializing this object shouldn't throw an exception");
    XCTAssert([analytics isKindOfClass:[WPAppAnalytics class]]);

    XCTAssertFalse([WPAppAnalytics userHasOptedOut]);
}

- (void)testOptOutMigrationWhenTrackingWasDisabled
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:WPAppAnalyticsDefaultsUserOptedOut];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:WPAppAnalyticsDefaultsKeyUsageTracking_deprecated];

    WPAppAnalytics *analytics = nil;
    WPAppAnalyticsLastVisibleScreenCallback lastVisibleScreenCallback = ^NSString*{
        return @"TEST";
    };

    XCTAssertNoThrow(analytics = [[WPAppAnalytics alloc] initWithLastVisibleScreenBlock:lastVisibleScreenCallback],
                     @"Allocating or initializing this object shouldn't throw an exception");
    XCTAssert([analytics isKindOfClass:[WPAppAnalytics class]]);

    XCTAssertTrue([WPAppAnalytics userHasOptedOut]);
}

- (void)testSiteTypeForBlog
{
    NSString *siteType = [WPAppAnalytics siteTypeForBlogWithID: @99999999];
    XCTAssertNotNil(siteType);
    XCTAssertTrue([siteType isEqualToString:@"blog"]);
}

@end
