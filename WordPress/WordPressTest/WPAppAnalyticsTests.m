//
//  WPAppAnalyticsTests.m
//  WordPress
//
//  Created by Diego E. Rey Mendez on 3/16/15.
//  Copyright (c) 2015 WordPress. All rights reserved.
//

#import <OCMock/OCMock.h>
#import <WordPressCom-Analytics-iOS/WPAnalytics.h>
#import <XCTest/XCTest.h>

#import "WPAppAnalytics.h"

@interface WPAppAnalyticsTests : XCTestCase
@end

@implementation WPAppAnalyticsTests

- (void)testInitialization
{
    id analyticsClassMock = [OCMockObject mockForClass:[WPAnalytics class]];
    
    [[analyticsClassMock expect] registerTracker:OCMOCK_ANY];
    
    WPAppAnalytics *analytics = nil;
    
    XCTAssertNoThrow(analytics = [[WPAppAnalytics alloc] init],
                     @"Allocating or initializing this object shouldn't throw an exception");
    XCTAssert([analytics isKindOfClass:[WPAppAnalytics class]]);
    
    [analyticsClassMock verify];
}

@end
