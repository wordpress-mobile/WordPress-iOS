#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <KIF/KIF.h>
#import "WordPressTestCredentials.h"
#import "WPUITestCase.h"

@interface LoginTests : WPUITestCase

@end

@implementation LoginTests

- (void)beforeAll
{
    [self logoutIfNeeded];
}

- (void)beforeEach
{
    if([tester tryFindingViewWithAccessibilityLabel:@"OK" error:nil]){
        [tester tapViewWithAccessibilityLabel:@"OK"];
    }
    
    if([tester tryFindingViewWithAccessibilityLabel:@"Sign in to WordPress.com" error:nil]){
        [tester tapViewWithAccessibilityLabel:@"Sign in to WordPress.com"];
    }
}

- (void)afterEach
{
    
}

- (void)testUnsuccessfulLogin
{
    [tester clearTextFromAndThenEnterText:@"unknow@unknow.com" intoViewWithAccessibilityIdentifier:@"Username / Email"];
    [tester clearTextFromAndThenEnterText:@"failpassword" intoViewWithAccessibilityIdentifier:@"Password"];
    [tester tapViewWithAccessibilityLabel:@"Sign In"];
    
    [tester waitForTimeInterval:3];
    // Verify that the login succeeded
    [tester waitForViewWithAccessibilityIdentifier:@"GenericErrorMessage"];
    
    [tester tapViewWithAccessibilityLabel:@"OK"];
}

- (void)testSimpleLogin
{
    [tester clearTextFromAndThenEnterText:oneStepUser intoViewWithAccessibilityIdentifier:@"Username / Email"];
    [tester clearTextFromAndThenEnterText:oneStepPassword intoViewWithAccessibilityIdentifier:@"Password"];
    [tester tapViewWithAccessibilityLabel:@"Sign In"];
    
    [tester waitForTimeInterval:3];
    // Verify that the login succeeded
    [tester waitForViewWithAccessibilityIdentifier:@"Main Navigation"];
    
    [self logout];
}

- (void)testTwoStepLogin
{
    [tester clearTextFromAndThenEnterText:twoStepUser intoViewWithAccessibilityIdentifier:@"Username / Email"];
    [tester clearTextFromAndThenEnterText:twoStepPassword intoViewWithAccessibilityIdentifier:@"Password"];
    [tester tapViewWithAccessibilityLabel:@"Sign In"];
    
    [tester waitForTimeInterval:3];
    // Verify that the login succeeded
    [tester waitForViewWithAccessibilityIdentifier:@"Main Navigation"];
    
    [self logout];
}

- (void)testSelfHostedLoginWithoutJetPack
{
    [tester tapViewWithAccessibilityLabel:@"Add Self-Hosted Site"];
    [tester enterText:selfHostedUser intoViewWithAccessibilityIdentifier:@"Username / Email"];
    [tester enterText:selfHostedPassword intoViewWithAccessibilityIdentifier:@"Password"];
    [tester enterText:selfHostedSiteURL intoViewWithAccessibilityIdentifier:@"Site Address (URL)"];
    [tester tapViewWithAccessibilityLabel:@"Add Site"];
        
    [tester waitForTimeInterval:3];
    // Verify that the login succeeded
    [tester waitForViewWithAccessibilityIdentifier:@"Main Navigation"];
    
    [tester tapViewWithAccessibilityLabel:@"My Sites"];
    [tester waitForTimeInterval:1];
    [tester tapViewWithAccessibilityLabel:@"My Sites"];
    [tester waitForTimeInterval:1];
    [tester tapViewWithAccessibilityLabel:@"Edit"];
    
    [tester tapViewWithAccessibilityLabel:[NSString stringWithFormat:@"Delete %@, %@", selfHostedSiteName, selfHostedSiteURL]];
    [tester tapViewWithAccessibilityLabel:@"Remove"];
}

- (void) testCreateAccount {
    NSString * username = [NSString stringWithFormat:@"%@%u", oneStepUser, arc4random()];
    [tester tapViewWithAccessibilityLabel:@"Create Account"];
    [tester enterText:[NSString stringWithFormat:@"%@@gmail.com", username] intoViewWithAccessibilityIdentifier:@"Email Address"];
    [tester enterText:username intoViewWithAccessibilityIdentifier:@"Username"];
    [tester enterText:oneStepPassword intoViewWithAccessibilityIdentifier:@"Password"];
    [tester clearTextFromAndThenEnterText:username intoViewWithAccessibilityIdentifier:@"Site Address (URL)"];
    [tester tapViewWithAccessibilityLabel:@"Create Account"];
    [tester waitForTimeInterval:10];
    [self logout];
}





@end
