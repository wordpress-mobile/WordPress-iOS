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
    [tester enterText:@"user@example.com" intoViewWithAccessibilityLabel:@"Username"];
    [tester enterText:@"thisismypassword" intoViewWithAccessibilityLabel:@"Password"];
    [tester tapViewWithAccessibilityLabel:@"SignIn"];
    
    // Verify that the login succeeded
    [tester waitForViewWithAccessibilityLabel:@"GenericErrorMessage"];
}
@end
