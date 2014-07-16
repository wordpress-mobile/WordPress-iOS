#import <Subliminal/Subliminal.h>
#import "IntegrationTestsInfo.h"

@interface LoginTest : SLTest

@end

@implementation LoginTest

- (void)setUpTest {
	// Navigate to the part of the app being exercised by the test cases,
	// initialize SLElements common to the test cases, etc.
}

- (void)tearDownTest {
	// Navigate back to "home", if applicable.
}

- (void)testLoginSucceedsWithUsernameAndPassword {
    SLTextField *usernameField = [SLTextField elementWithAccessibilityIdentifier:@"Username"];
    SLTextField *passwordField = [SLTextField elementWithAccessibilityIdentifier:@"Password"];
    SLElement *submitButton = [SLElement elementWithAccessibilityIdentifier:@"Sign In"];
    
    [usernameField setText:[IntegrationTestsInfo WPComUsername]];
    [passwordField setText:[IntegrationTestsInfo WPComPassword]];
    
    [submitButton tap];
    
    SLAssertTrueWithTimeout([[SLElement elementWithAccessibilityIdentifier:@"tabBar"] isValid],
                            5.0,
                            @"Sign in was not successful.");
}

- (void)testLogoutSucceeds {
    [[SLElement elementWithAccessibilityLabel:@"Me"] tap];
    [[SLElement elementWithAccessibilityLabel:@"Settings"] tap];
    [[SLElement elementWithAccessibilityIdentifier:@"wpcom-sign-out"] tap];
    [[SLElement elementWithAccessibilityLabel:@"Sign Out"] tap];
    
    SLAssertTrueWithTimeout([[SLTextField elementWithAccessibilityIdentifier:@"Username"] isValid],
                            5.0,
                            @"Sign out failed.");
}

@end
