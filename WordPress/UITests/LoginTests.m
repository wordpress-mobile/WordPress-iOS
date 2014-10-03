//
//  LoginTests.m
//  LoginTests
//
//  Created by Sergio Estevao on 01/10/2014.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <KIF/KIF.h>
#import "WordPressTestCredentials.h"

@interface LoginTests : KIFTestCase

@end

@implementation LoginTests

- (void)beforeEach
{
    
}

- (void)afterEach
{
    
}

- (void)testUnsuccessfulLogin
{
    [tester enterText:@"unknow@unknow.com" intoViewWithAccessibilityLabel:@"Username"];
    [tester enterText:@"failpassword" intoViewWithAccessibilityLabel:@"Password"];
    [tester tapViewWithAccessibilityLabel:@"SignIn"];
    
    [tester waitForTimeInterval:3];
    // Verify that the login succeeded
    [tester waitForViewWithAccessibilityLabel:@"GenericErrorMessage"];
    
    [tester tapViewWithAccessibilityLabel:@"OK"];
}

- (void)testSimpleLogin
{
    [tester enterText:oneStepUser intoViewWithAccessibilityLabel:@"Username"];
    [tester enterText:oneStepPassword intoViewWithAccessibilityLabel:@"Password"];
    [tester tapViewWithAccessibilityLabel:@"SignIn"];
    
    [tester waitForTimeInterval:3];
    // Verify that the login succeeded
    [tester waitForViewWithAccessibilityLabel:@"MainTabBar"];
    
    [self logout];
}

- (void)testTwoStepLogin
{
    [tester enterText:twoStepUser intoViewWithAccessibilityLabel:@"Username"];
    [tester enterText:twoStepPassword intoViewWithAccessibilityLabel:@"Password"];
    [tester tapViewWithAccessibilityLabel:@"SignIn"];
    
    [tester waitForTimeInterval:3];
    // Verify that the login succeeded
    [tester waitForViewWithAccessibilityLabel:@"MainTabBar"];
    
    [self logout];
}

- (void)testSelfHostedLoginWithJetPack
{
    [tester tapViewWithAccessibilityLabel:@"ToggleSignInForm"];
    [tester enterText:selfHostedUser intoViewWithAccessibilityLabel:@"Username"];
    [tester enterText:selfHostedPassword intoViewWithAccessibilityLabel:@"Password"];
    [tester enterText:selfHostedSiteURL intoViewWithAccessibilityLabel:@"SiteURL"];
    [tester tapViewWithAccessibilityLabel:@"SignIn"];
    
    [tester waitForTimeInterval:3];
    [tester tapViewWithAccessibilityLabel:@"Skip"];
    
    [tester waitForTimeInterval:3];
    // Verify that the login succeeded
    [tester waitForViewWithAccessibilityLabel:@"MainTabBar"];
    
    [tester tapViewWithAccessibilityLabel:@"EditButton"];
    
    [tester tapViewWithAccessibilityLabel:[NSString stringWithFormat:@"Delete %@, %@", selfHostedSiteName, selfHostedSiteURL]];
    [tester tapViewWithAccessibilityLabel:@"Remove"];
}

- (void)logout
{
    [tester tapViewWithAccessibilityLabel:@"SettingsButton"];
    [tester tapViewWithAccessibilityLabel:@"wpcom-sign-out"];
    [tester tapViewWithAccessibilityLabel:@"Sign Out"];
    
    [tester waitForTimeInterval:3];
}



@end
