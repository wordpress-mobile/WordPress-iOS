#import <Subliminal/Subliminal.h>

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
    
    
    NSString *username = @"Jeff", *password = @"foo";
    [usernameField setText:username];
    [passwordField setText:password];
    
    [submitButton tap];
    
    SLAssertTrueWithTimeout([[SLElement elementWithAccessibilityIdentifier:@"tabBar"] isValid],
                            5.0,
                            @"Sign in was not successful.");
}

@end
